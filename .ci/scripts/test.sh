set -ex
TASK_ROOT=$(pwd)

apk add --no-progress --no-cache git

## Install helm and ct same version
source <(curl -s https://raw.githubusercontent.com/pratikbalar/bash-functions/main/functions.sh)
tarr https://get.helm.sh/helm-${CT_VERSION}-linux-amd64.tar.gz linux-amd64/helm /usr/bin/helm
tarr https://github.com/helm/chart-testing/releases/download/${CT_VERSION}/chart-testing_${CT_VERSION/v/}_linux_amd64.tar.gz ct /usr/bin/ct

## Check if there any changes
cd repo
[[ "" == $(ct list-changed --config ct.yaml --since $(head -n1 status) 2>/dev/null) ]] && echo "########### no changes found ###########" && exit 0

## Start Docker
cd ..
source /docker-lib.sh
start_docker

# Cleanup.
# Not sure if this is required.
# It's quite possible that Concourse is smart enough to clean up the Docker mess itself.
function cleanup() {
  kind delete clusters ${KIND_VERSION}
  [[ ! -z $(docker ps -a -q) ]] && docker rm -f $(docker ps -a -q)
  [[ ! -z $(docker images ls -a -q) ]] && docker rmi -f $(docker images -a -q)
  [[ ! -z $(docker volume ls -q) ]] && docker volume rm -f $(docker volume ls -q)
}
trap cleanup EXIT

# Strictly speaking, preloading of Docker images is not required.
# However, you might want to do this for a couple of reasons:
# - If the image comes from a private repository, it is much easier to let Concourse pull it,
#   and then pass it through to the task.
# - When the image is passed to th  e task, Concourse can often get the image from its cache.
KIND_VERSION="${KIND_NODE_VERSION:-$(cat kind-img/tag)}"
if [[ ! -f kind-img/tag ]]; then
  docker pull kindest/node:${KIND_VERSION}
else
  docker load -i kind-img/image
  docker tag "$(cat kind-img/image-id)" "$(cat kind-img/repository):$(cat kind-img/tag)"
fi

## installing kubectl
apk add --no-cache --no-progress -X http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl
curl -Lso /usr/bin/kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
chmod a+x /usr/bin/kind

## create cluster with verbose
kind create cluster --image kindest/node:"${KIND_VERSION}" --name "${KIND_VERSION}" -v 5

## Wait for cluster to come up
kind get clusters
echo "Waiting for cluster to come up"
sleep 20
while [[ $(kubectl get pods -A -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == *"False"* ]]; do
  echo "#### Pods are not ready, waiting... ####"
  kubectl get pods -A
  sleep 5
done
echo "#### Cluster is ready ####"
kubectl get all,sc,cs -A

## set SKIP_ERR if you want to ignore ct testing
[[ ${SKIP_ERR} == *"true"* ]] && set +e
cd repo
export HELM_CONFIG_HOME=./
ct install --config ct.yaml --since $(head -n1 status) --debug
