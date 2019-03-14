cd C:/dev/screening/okta-dotnetcore-react-example/cloud-ops/azure/devops-sandbox-cluster/terraform
echo "$(terraform output kube_config)" > ../.secrets/kube_config
export KUBECONFIG=/c/dev/screening/okta-dotnetcore-react-example/cloud-ops/azure/devops-sandbox-cluster/.secrets/kube_config
export CLUSTER_NAME=devopsk8s
export CLUSTER_FILES_PATH=/c/dev/screening/okta-dotnetcore-react-example/cloud-ops/azure/devops-sandbox-cluster
export COMMON_FILES_PATH=/c/dev/screening/okta-dotnetcore-react-example/cloud-ops/azure/common
export COMMON_BASH_FILES_PATH=/c/dev/screening/okta-dotnetcore-react-example/cloud-ops/azure/common/bash-files
cd /c/dev/screening/okta-dotnetcore-react-example/cloud-ops/azure/devops-sandbox-cluster
