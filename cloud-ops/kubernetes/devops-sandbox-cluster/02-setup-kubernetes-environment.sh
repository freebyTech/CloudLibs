#!/bin/bash

# 
#   Sets up the environment and secrets necessary for the devops-sandbox-cluster Kubernetes instance in Azure.
#    
#   Authors: James Eby
#

export ORIG_DIR=$(pwd)

# Establishes connection to kubernetes cluster.
. ../../azure/devops-sandbox-cluster/init-kube-connection.sh

# Reset back to local directory.
cd $ORIG_DIR

# Set necessary secrets as environment variables.
. ../../azure/devops-sandbox-cluster/.secrets/set-sql-server-environment-variables.sh
. ./.secrets/set-external-resources-environment-variables.sh

# NAMESPACES
# Create namespace build for jenkins and harbor.
kubectl create -f ../common/Namespace/build-namespace.yaml
# Create the production namespace
kubectl create -f ../common/Namespace/production-namespace.yaml

# DNS RESOLUTIONS
# Create the local DNS resolution and upstream DNS resolution for the cluster.
#kubectl apply -f ../common/ConfigMap/externalDnsResolution.yaml

# SERVICE ACCOUNTS
# Create service account and RBAC for jenkins build server account.
kubectl create sa jenkins-builder -n build
kubectl create clusterrolebinding jenkins-cr-binding --clusterrole cluster-admin --serviceaccount=build:jenkins-builder

# With Azure RBAC enabled we need to give the kubernetes-dashboard user proper RBAC administer cluster resources
kubectl create clusterrolebinding kubernetes-dashboard-cr-binding --clusterrole cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

# Create service account and RBAC for tiller.
kubectl create sa tiller -n kube-system
kubectl create clusterrolebinding tiller-cr-binding --clusterrole cluster-admin --serviceaccount=kube-system:tiller

# SECRETS

#NOTE: NEVER EVER PUT A $ IN A PASSWORD FOR THESE USERS, it won't work -p parameter which also affects Jenkins.
if [ "$REGISTRY_URL" == 'hub.docker.com' ]
then
    # Create the private docker registry connection secret.
    kubectl create secret docker-registry freebytech-regcred --docker-server=https://index.docker.io/v1/ --docker-username=$REGISTRY_USER --docker-password=$REGISTRY_USER_PASSWORD --docker-email=$REGISTRY_EMAIL
    kubectl create secret docker-registry freebytech-regcred -n build --docker-server=https://index.docker.io/v1/ --docker-username=$REGISTRY_USER --docker-password=$REGISTRY_USER_PASSWORD --docker-email=$REGISTRY_EMAIL
    kubectl create secret docker-registry freebytech-regcred -n production --docker-server=https://index.docker.io/v1/ --docker-username=$REGISTRY_USER --docker-password=$REGISTRY_USER_PASSWORD --docker-email=$REGISTRY_EMAIL
else
    # Create the private docker registry connection secret.
    kubectl create secret docker-registry freebytech-regcred --docker-server=https://${REGISTRY_URL} --docker-username=$REGISTRY_USER --docker-password=$REGISTRY_USER_PASSWORD --docker-email=$REGISTRY_EMAIL
    kubectl create secret docker-registry freebytech-regcred -n build --docker-server=https://${REGISTRY_URL} --docker-username=$REGISTRY_USER --docker-password=$REGISTRY_USER_PASSWORD --docker-email=$REGISTRY_EMAIL
    kubectl create secret docker-registry freebytech-regcred -n production --docker-server=https://${REGISTRY_URL} --docker-username=$REGISTRY_USER --docker-password=$REGISTRY_USER_PASSWORD --docker-email=$REGISTRY_EMAIL
fi

# Give jenkins service account right to pull images from private repository.
kubectl patch serviceaccount -n build jenkins-builder -p '{"imagePullSecrets": [{"name": "freebytech-regcred"}]}'

# Create the jenkins credentials.xml file secret.
kubectl create secret generic jenkins-credentials -n build --from-file ./.secrets/jenkins/credentials.xml

# Create the master.key and hudson.util.Secret files secret.
kubectl create secret generic jenkins-secrets -n build --from-file ./.secrets/jenkins/hudson.util.Secret --from-file ./.secrets/jenkins/master.key

# Setup external resource secrets for use by jenkins and potentially others.
kubectl create secret generic jenkins-env-secrets -n build \
    --from-literal=addenv_REGISTRY_URL=$REGISTRY_URL \
    --from-literal=addenv_REGISTRY_USER_ID=$REGISTRY_USER_ID \
    --from-literal=addenv_PRIVATE_GIT_REPO_URL=$PRIVATE_GIT_REPO_URL \
    --from-literal=addenv_PRIVATE_GIT_REPO_USER_ID=$PRIVATE_GIT_REPO_USER_ID \
    --from-literal=addenv_PUBLIC_GIT_REPO_URL=$PUBLIC_GIT_REPO_URL \
    --from-literal=addenv_PUBLIC_GIT_REPO_USER_ID=$PUBLIC_GIT_REPO_USER_ID \
    --from-literal=addenv_NUGET_API_KEY=$NUGET_API_KEY \
    --from-literal=addenv_AGENT_IMAGE=jenkins-agent:latest

# Setup standard mail secrets for use by multiple apps.
kubectl create secret generic smtp-env-secrets -n production \
    --from-literal=MAIL__SMTPSERVER=$MAIL__SMTPSERVER \
    --from-literal=MAIL__SMTPPORT=$MAIL__SMTPPORT \
    --from-literal=MAIL__SMTPUSERNAME=$MAIL__SMTPUSERNAME \
    --from-literal=MAIL__SMTPPASSWORD=$MAIL__SMTPPASSWORD \
    --from-literal=MAIL__SMTPENABLESSL=$MAIL__SMTPENABLESSL

# Setup standard db secrets for use by multiple apps.
kubectl create secret generic db-env-secrets -n production \
    --from-literal=DB__SERVERNAME=$AZURE_SQL_SERVER \
    --from-literal=DB__USERNAME=$AZURE_SQL_SERVER_ADMIN_USER \
    --from-literal=DB__USERPASSWORD=$AZURE_SQL_SERVER_ADMIN_PASSWORD

# Setup standard db secrets for use by multiple apps.
kubectl create secret generic sts-env-secrets -n production \
    --from-literal=OKTA_CLIENT_CONNECTIONTIMEOUT=$OKTA_CLIENT_CONNECTIONTIMEOUT \
    --from-literal=OKTA_CLIENT_OKTADOMAIN=$OKTA_CLIENT_OKTADOMAIN \
    --from-literal=OKTA_CLIENT_TOKEN=$OKTA_CLIENT_TOKEN