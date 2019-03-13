#!/bin/bash

# 
#   Installs nginx ingress, cert manager, harbor, and jenkins into the kubernetes cluster.
#    
#   Authors: James Eby
#

export ORIG_DIR=$(pwd)

# Establishes connection to kubernetes cluster.
. ../../azure/devops-sandbox-cluster/init-kube-connection.sh
. $COMMON_BASH_FILES_PATH/install-helm-locally.sh

cd $CLUSTER_FILES_PATH

helm init --service-account tiller

echo 'Sleeping for 30 seconds'
sleep 30s

# Reset back to local directory.
cd $ORIG_DIR

# Set necessary secrets as environment variables.
. ./.secrets/set-user-environment-variables.sh

# Need to wait till tiller is available.
helm install stable/nginx-ingress --name nginx-ingress --namespace kube-system --set controller.hostNetwork=true --set controller.kind=DaemonSet
helm install stable/cert-manager --name cert-manager --namespace kube-system --set ingressShim.defaultIssuerName=letsencrypt-staging-clusteri --set ingressShim.defaultIssuerKind=ClusterIssuer

kubectl create -f $COMMON_FILES_PATH/k8s-resources/ClusterIssuer/letsencrypt-production.yaml

# Create a network tester for testing the internal network of the cluster.
kubectl create -f ../common/Deployment/busyBoxTester.yaml

# Setup harbor
git clone https://github.com/goharbor/harbor-helm harbor-helm

cd ./harbor-helm

# Commits from 11-21-2018 broke persistence, need to investigate values.yaml changes in future.
git checkout -b 1.0.0 origin/1.0.0

helm dependency update
helm upgrade --install --namespace build harbor -f ../Deployment/harbor-helm-values.yaml .

cd ..
helm upgrade --install --namespace build freeby-jenkins -f ./Deployment/freeby-jenkins-values.yaml stable/jenkins

