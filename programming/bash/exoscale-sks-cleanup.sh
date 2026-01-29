#!/bin/bash

# Author: Marco Platzer
# Date: 25-03-2025
# Description: This script removes all the deployed resources of your sks cluster on Exoscale

# Usage: ./cleanup.sh
# Make sure to remove services and deployments first. With that you Cleanup the Load Balancer Service on Exoscale.

set -e
set -o pipefail
# set -x

CLUSTER_NAME="latzok8s"
NODEPOOL_NAME="nodes-k8s-001"
SECURITY_GROUP="nsg-k8s-001"

# Function to delete the SKS Nodepool
delete_nodepool() {
    if exo compute sks nodepool show ${CLUSTER_NAME} ${NODEPOOL_NAME} 2>/dev/null; then
        echo "Deleting SKS Nodepool: ${NODEPOOL_NAME}..."
        exo compute sks nodepool delete ${CLUSTER_NAME} ${NODEPOOL_NAME}
    else 
        echo "Nodepool ${NODEPOOl_NAME} does not exist. Skipping deletion."
    fi
}

# Function to delete SKS cluster if it exists
delete_cluster() {
    if exo compute sks show ${CLUSTER_NAME} 2>/dev/null; then
        echo "Deleting SKS cluster: ${CLUSTER_NAME}..."
        exo compute sks delete ${CLUSTER_NAME}
    else
        echo "Cluster ${CLUSTER_NAME} does not exist. Skipping deletion."
    fi
}

# Function to delete security group if it exists
delete_security_group() {
    if exo compute security-group show ${SECURITY_GROUP} 2>/dev/null; then
        echo "Deleting security group: ${SECURITY_GROUP}..."
        exo compute security-group delete ${SECURITY_GROUP}
    else
        echo "Security group ${SECURITY_GROUP} does not exist. Skipping deletion."
    fi
}

# Delete the SKS Nodepool
delete_nodepool

# Delete the SKS cluster
delete_cluster

# Delete the security group
delete_security_group

echo "Cleanup process completed."
