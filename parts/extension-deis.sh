#!/bin/bash

#### Make sure to add your ssh keys to the box where you will run this script and define the hard coded variables below

# Local variables

export ADMIN_USERNAME=$1
export AZURE_STORAGE_ACCOUNT=$2
export AZURE_STORAGE_ACCESS_KEY=$3

# Install kubernetes client
wget https://storage.googleapis.com/kubernetes-release/release/v1.4.4/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl

# Install deis
curl -sSL http://deis.io/deis-cli/install-v2.sh | bash
mv deis /usr/local/bin/deis

# Install helm
curl -sSL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get  | bash

# Install deis on kub cluster
helm init
helm install deis/workflow --namespace=deis --set controller.docker_tag=v2.9.0-acs,controller.org=kmala,global.storage=azure,azure.accountname=$AZURE_STORAGE_ACCOUNT,azure.accountkey=$AZURE_STORAGE_ACCESS_KEY,azure.registry_container=registry,azure.database_container=database,azure.builder_container=builder
