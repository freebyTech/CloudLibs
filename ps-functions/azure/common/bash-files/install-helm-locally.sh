curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > $CLUSTER_FILES_PATH/get_helm.sh
export USE_SUDO="false"
export HELM_INSTALL_DIR=$CLUSTER_FILES_PATH/helm
export PATH=$PATH:$HELM_INSTALL_DIR

mkdir $HELM_INSTALL_DIR
$CLUSTER_FILES_PATH/get_helm.sh