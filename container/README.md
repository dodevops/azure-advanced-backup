# Azure Advanced Backup

Container image based on Azure CLI and AZCopy that supports backing up and
syncing databases and storages in Azure.

Current set of features:

* Backup Azure Database For PostgreSQL database dumps in a container in a backup storage account
* Sync Storage Containers to other containers into a container in a backup storage account
* Snapshot Azure Managed Disks to a VHD file and store it in a container in backup storage account

## Prerequisites

This image requires a registered Azure application, that is used to login to Azure and with AZCopy to 
manage the backup, synchronisations and snapshots.

Create one using

    az ad sp create-for-rbac --name="backup" --role="Owner" --scopes="/subscriptions/${SUBSCRIPTION_ID}"

(assuming the environment variable SUBSCRIPTION_ID holds your subscription id)

Note the application id and the returned secret.

**Warning**: Remember to check the lifetime of the secret and generate new secrets to keep the backup
job running.

## Usage

Start the container with the following environment variables to configure the
solution:

- Authentication
  - **AZ_APPLICATION_ID**: The id of the application to authenticate with
  - **AZCOPY_SPA_CLIENT_SECRET**: The secret of the application
  - **AZ_TENANT_ID**: Azure tenant id
- Backup configuration
  - **BACKUP_STORAGE_ACCOUNT**: Name of the storage account to sync the containers to
  - **BACKUP_STORAGE_CONTAINER**: Name of the storage container to sync the container contents to
- Azure Database For PostgreSQL backup
  - **PG_DATABASES**: Whitespace separated list of database logins in the form
    `BACKUP_NAME:USERNAME:PASSWORD:HOST:DATABASE_NAME`
- Azure Storage Container synchronisation
  - **CONTAINERS**: Whitespace separated list of storage containers  in the form
    `BACKUP_NAME:STORAGE_ACCOUNT_NAME:CONTAINER_NAME`
- Azure Managed Disk backup
  - **MANAGED_DISKS**: Whitespace separated list of managed disks in the form
    `DISK_NAME:DISK_URI:RESOURCEGROUP_NAME`
  - **RESOURCE_GROUP_LOCK_ID**: Set to the id of a resource group lock to remove when deleting snapshots and recreate 
    it afterwards
  - **COPY_SNAPSHOTS**: If set to "true", copies the managed disk snapshots as a single VHD into the backup storage 
    account. The existing VHD will be overwritten. If not set to "true", the snapshots will stay where they
    were created and get deleted after the days given in snapshotRetentionDays.
  - **SNAPSHOT_RETENTION_DAYS**: Number of days to keep a snapshot. Note that this only applies if copySnapshots is 
    set to false.
- General
  - **DEBUG**: Set to "yes" to enable debug output. **WARNING** This will potentially output sensitive information
    to the log!
