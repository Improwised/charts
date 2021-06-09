set -ex
TASK_ROOT=$(pwd)
cd repo
[[ "" == $(ct list-changed --config ct.yaml --since $(head -n1 status) 2>/dev/null) ]] && echo "########### no changes found ###########" && exit 0

## Set git user email and name for commiting
git config --global user.email concourse@github-noreply.com
git config --global user.name concourse

export HELM_CONFIG_HOME=$(pwd)/
tail -n+2 status >${TASK_ROOT}/bumping
## Package and index charts, taking input from bumping file
while read -r line; do
  CHART=($line)
  echo "########### Packaging ${CHART[0]} ###########"
  helm package -u -d ${TASK_ROOT}/charts/charts ${CHART[0]}

  cd ${TASK_ROOT}/charts
  helm repo index --url https://improwised.github.io/charts .
  git add .
  git commit -m "bump: ${CHART[0]/charts\//}:- ${CHART[1]} → ${CHART[2]}"

  cd ${TASK_ROOT}/repo
done <${TASK_ROOT}/bumping
