set -ex
TASK_ROOT=$(pwd)
cd repo
## ct linting
export HELM_CONFIG_HOME=./
ct lint --target-branch master --remote origin --config ct.yaml --debug
