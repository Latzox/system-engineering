#!/bin/bash

# Author: Marco Platzer
# Date: 18-03-2025
# Description: This script deploys a Kubernetes Cluster on Exoscale.

# Usage: ./deploy.sh

set -e
set -o pipefail
# set -x

ZONE="ch-dk-2"
CLUSTER_NAME="latzok8s"
NODEPOOL_NAME="nodes-k8s-001"
NODEPOOL_INSTANCE_TYPE="standard.small"
NODEPOOL_DISK_SIZE=20
SECURITY_GROUP="nsg-k8s-001"
KUBECONFIG_FILE="${CLUSTER_NAME}.kubeconfig"

# Check if security group exists
if ! exo compute security-group show ${SECURITY_GROUP} &>/dev/null; then
    echo "Creating security group: ${SECURITY_GROUP}..."
    exo compute security-group create ${SECURITY_GROUP}
else
    echo "Security group ${SECURITY_GROUP} already exists. Skipping creation."
fi

# Function to check if a rule exists in the security group
rule_exists() {
    local description="$1"
    exo compute security-group show ${SECURITY_GROUP} -O json | jq -r '.ingress_rules[].description' | grep -q "$description"
}

# Add rules to security group if not present
declare -A RULES
RULES["NodePort services"]="--protocol tcp --network 0.0.0.0/0 --port 30000-32767"
RULES["SKS kubelet"]="--protocol tcp --port 10250 --security-group ${SECURITY_GROUP}"
RULES["Calico traffic"]="--protocol udp --port 4789 --security-group ${SECURITY_GROUP}"

for desc in "${!RULES[@]}"; do
    if ! rule_exists "$desc"; then
        echo "Adding rule: $desc"
        exo compute security-group rule add ${SECURITY_GROUP} --description "$desc" ${RULES[$desc]}
    else
        echo "Security rule already exists: $desc"
    fi
done

# Check if cluster exists
if ! exo compute sks show ${CLUSTER_NAME} --zone ${ZONE} &>/dev/null; then
    echo "Creating SKS cluster: ${CLUSTER_NAME}..."
    exo compute sks create ${CLUSTER_NAME} \
        --zone ${ZONE} \
        --service-level starter \
        --nodepool-name ${NODEPOOL_NAME} \
        --nodepool-size 2 \
        --nodepool-instance-type ${NODEPOOL_INSTANCE_TYPE} \
        --nodepool-disk-size ${NODEPOOL_DISK_SIZE} \
        --nodepool-security-group ${SECURITY_GROUP} \
        --auto-upgrade
else
    echo "Cluster ${CLUSTER_NAME} already exists. Skipping creation."
fi

# Wait for cluster to be provisioned
echo "Waiting for cluster to be provisioned..."
sleep 30  # Adjust based on Exoscale provisioning time

# Show cluster details
exo compute sks list
exo compute sks show ${CLUSTER_NAME} --zone ${ZONE}

# Generate kubeconfig file if not exists
if [ ! -f ${KUBECONFIG_FILE} ]; then
    echo "Generating kubeconfig..."
    exo compute sks kubeconfig ${CLUSTER_NAME} kube-admin \
        --zone ${ZONE} \
        --group system:masters > ${KUBECONFIG_FILE}
else
    echo "Kubeconfig file already exists. Skipping generation."
fi

# Verify cluster nodes
echo "Checking cluster nodes..."
kubectl --kubeconfig ${KUBECONFIG_FILE} get nodes
