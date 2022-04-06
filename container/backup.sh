#!/usr/bin/env bash

# Login into AZ and AZCopy

az login --service-principal --username "${AZ_APPLICATION_ID}" --password "${AZCOPY_SPA_CLIENT_SECRET}" --tenant "${AZ_TENANT_ID}"
azcopy login --service-principal --application-id "${AZ_APPLICATION_ID}" --tenant-id "${AZ_TENANT_ID}"

# SAS Tokens

SAS_BACKUP=$(az storage container generate-sas --account-name "${BACKUP_STORAGE_ACCOUNT}" --name "${BACKUP_STORAGE_CONTAINER}" --as-user --expiry="$(date -u -d '+2 hours' +%Y-%m-%dT%H:%M:%SZ)" --auth-mode login --permissions acdlrw --output tsv)

# Dump databases

if [ -n "${PG_DATABASES}" ]
then
  for DATABASE in ${PG_DATABASES}
  do
    NAME=$(echo "${DATABASE}" | cut -d ":" -f 1)
    DATABASE_USERNAME=$(echo "${DATABASE}" | cut -d ":" -f 2)
    DATABASE_PASSWORD=$(echo "${DATABASE}" | cut -d ":" -f 3)
    DATABASE_HOST=$(echo "${DATABASE}" | cut -d ":" -f 4)
    DATABASE_NAME=$(echo "${DATABASE}" | cut -d ":" -f 5)
    echo "Dumping ${NAME}"
    echo "${DATABASE_HOST}:5432:${DATABASE_NAME}:${DATABASE_USERNAME}@${DATABASE_HOST}:${DATABASE_PASSWORD}" > ~/.pgpass
    chmod 0600 ~/.pgpass
    pg_dump --host="${DATABASE_HOST}" --dbname="${DATABASE_NAME}" --username="${DATABASE_USERNAME}@${DATABASE_HOST}" > dump.sql
    azcopy copy --overwrite true dump.sql "https://${BACKUP_STORAGE_ACCOUNT}.blob.core.windows.net/${BACKUP_STORAGE_CONTAINER}/databases/${NAME}.$(date +%u).sql?${SAS_BACKUP}"
  done
fi

# Sync containers

if [ -n "${CONTAINERS}" ]
then
  for CONTAINER in ${CONTAINERS}
  do
    NAME=$(echo "${CONTAINER}" | cut -d ":" -f 1)
    ACCOUNT=$(echo "${CONTAINER}" | cut -d ":" -f 2)
    CONTAINER=$(echo "${CONTAINER}" | cut -d ":" -f 3)
    echo "Syncing container ${NAME}"
    SAS_TOKEN=$(az storage container generate-sas --account-name "${ACCOUNT}" --name "${CONTAINER}" --as-user --expiry="$(date -u -d '+2 hours' +%Y-%m-%dT%H:%M:%SZ)" --auth-mode login --permissions lr --output tsv)
    azcopy sync --s2s-preserve-access-tier=false --delete-destination true "https://${ACCOUNT}.blob.core.windows.net/${CONTAINER}?${SAS_TOKEN}" "https://${BACKUP_STORAGE_ACCOUNT}.blob.core.windows.net/${BACKUP_STORAGE_CONTAINER}/containers/${NAME}?${SAS_BACKUP}"
  done
fi

# Snapshot managed disks

if [ -n "${MANAGED_DISKS}" ]
then
  for DISK in ${MANAGED_DISKS}
  do
    DISKNAME=$(echo "${DISK}" | cut -d ":" -f 1)
    NAME=${DISKNAME//disk/snap}
    DISKURI=$(echo "${DISK}" | cut -d ":" -f 2)
    RESOURCEGROUP=$(echo "${DISK}" | cut -d ":" -f 3)
    echo "Creating snapshot ${NAME}"
    az snapshot create --resource-group "${RESOURCEGROUP}" --name "${NAME}" --source "${DISKURI}"
    SAS=$(az snapshot grant-access --resource-group "${RESOURCEGROUP}" --name "${NAME}" --duration-in-seconds 360 --access-level Read --query "[accessSas]" -o tsv)
    echo "Copying snapshot to backup storage"
    azcopy copy --overwrite true "${SAS}" "https://${BACKUP_STORAGE_ACCOUNT}.blob.core.windows.net/${BACKUP_STORAGE_CONTAINER}/snapshots/${NAME}.vhd?${SAS_BACKUP}"
    echo "Deleting snapshot"
    az snapshot revoke-access --resource-group "${RESOURCEGROUP}" --name "${NAME}"
    az snapshot delete --resource-group "${RESOURCEGROUP}" --name "${NAME}"
  done
fi
