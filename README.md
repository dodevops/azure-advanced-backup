# Azure Advanced Backup

Azure backup of databases and containers in a Kubernetes Cronjob

## Introduction

This repository contains a container image and a Helm chart for a 
solution to backup Azure databases and storages from inside a (Azure) Kubernetes
cluster.

This solution is used in-house and highly opinionated.

Current set of features:

* Backup Azure Database For PostgreSQL database dumps in a container in a backup storage account
* Sync Storage Containers to other containers into a container in a backup storage account
* Snapshot Azure Managed Disks to a VHD file and store it in a container in backup storage account

## Usage

See the [Helm Chart documentation for usage and configuration](helm-charts/azure-advanced-backup/README.md)

## Development

The chart is developed in the directory helm-charts/azure-advanced-backup and the
container image and script in container.

Please keep the [container documentation](container/README.md) and the 
[chart documentation](helm-charts/azure-advanced-backup/README.md) up to date after
changing.

Use

    $ docker run --rm --volume $(pwd):/helm-docs jnorwood/helm-docs:latest

to update the helm chart documentation.
