#!/bin/bash

#### Make sure to add your ssh keys to the box where you will run this script and define the hard coded variables below

# Local variables

export ADMIN_USERNAME=$1
export MASTER_K8S_IP=$2

# put in .profile
echo 'export MASTER_K8S_IP='$MASTER_K8S_IP >> $HOME/.profile

#run this command the first time to make sure keys are distributed
scp -i ~/.ssh/id_rsa $ADMIN_USERNAME@$MASTER_K8S_IP:.kube/config ./$MASTER_K8S_IP.kubeconfig

export KUBECONFIG=/home/$ADMIN_USERNAME/$MASTER_K8S_IP.kubeconfig
echo 'export KUBECONFIG='$KUBECONFIG >> $HOME/.profile
chmod 655 $MASTER_K8S_IP.kubeconfig 
source $HOME/.profile

#'install kubernetes client'
wget https://storage.googleapis.com/kubernetes-release/release/v1.4.4/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

#install deis
curl -sSL http://deis.io/deis-cli/install-v2.sh | bash
sudo mv deis /usr/local/bin/deis

#install helm
curl -sSL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get  | bash

#install deis on kub cluster
helm init
helm repo add deis https://charts.deis.com/workflow
helm install deis/workflow --namespace deis

#check progress of deis running
kubectl --namespace=deis get pods

echo "run this to see progress: kubectl --namespace=deis get pods"




