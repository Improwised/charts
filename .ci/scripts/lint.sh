set -ex
TASK_ROOT=$(pwd)
cd repo
git fetch --all
[[ $(ct list-changed --config ct.yaml --since $(head -n1 status) 2>/dev/null) == "" ]] && echo "#### no changes found ####" && exit 0

## ct linting
export HELM_CONFIG_HOME=./
ct lint --config ct.yaml --since $(head -n1 status) --debug
