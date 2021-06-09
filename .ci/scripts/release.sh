set -ex
TASK_ROOT=$(pwd)
cd repo
[[ "" == $(ct list-changed --config ct.yaml --since $(head -n1 status)) ]] && echo "########### no changes found ###########" && exit 0

## Functioon for git feching in concoures for ssh or https based repos
# function git_fetch() {
#   if [[ $(git config --get remote.origin.url) == *"git@github.com"* ]]; then
#     mkdir -p ~/.ssh
#     [[ -z $KEY ]] && echo "#### env var \$KEY not found" && exit 1
#     touch ~/.ssh/id_rsa ~/.ssh/known_hosts
#     echo $KEY | base64 -d >~/.ssh/id_rsa
#     chmod 700 ~/.ssh/id_rsa
#     ssh-keyscan github.com >>~/.ssh/known_hosts

#     git config remote.origin.fetch refs/heads/*:refs/remotes/origin/*
#     git fetch --all
#     git fetch $(git config --get remote.origin.url) 'refs/tags/*:refs/tags/*'
#   else
#     git config remote.origin.fetch refs/heads/*:refs/remotes/origin/*
#     git fetch --all
#   fi
# }
# git_fetch

## Set git user email and name for commit
git config --global user.email concourse@github-noreply.com
git config --global user.name concourse

## install necessary tools and setup minio
source <(curl -s https://raw.githubusercontent.com/pratikbalar/bash-functions/main/functions.sh)
tarr https://github.com/tcnksm/ghr/releases/download/v0.13.0/ghr_v0.13.0_linux_amd64.tar.gz ghr_v0.13.0_linux_amd64/ghr /usr/bin/ghr
tarr https://github.com/git-chglog/git-chglog/releases/download/v0.14.2/git-chglog_0.14.2_linux_amd64.tar.gz git-chglog /usr/local/bin/git-chglog

PROJECT_USERNAME=$(git config --get remote.origin.url | sed 's/git\@github\.com\:\|\.git\|https\:\/\/github\.com\///g' | awk -F\/ '{printf $1}')
PROJECT_REPONAME=$(git config --get remote.origin.url | sed 's/git\@github\.com\:\|\.git\|https\:\/\/github\.com\///g' | awk -F\/ '{printf $2}')
tail -n+2 status >${TASK_ROOT}/bumping

while read -r line; do
  ## Extract info from array
  CHART=($line)
  CHART_NAME=${CHART[0]/charts\//}
  OLD_VERSION=${CHART[1]}
  NEW_VERSION=${CHART[2]}
  COMMIT_SHA=${CHART[3]}

  ## Create temporary tag for generating generating proper changelog
  git tag ${CHART_NAME}-${NEW_VERSION} ${COMMIT_SHA}
  git-chglog -o /tmp/${CHART_NAME}-${NEW_VERSION}.md \
    --config .ci/git-chglog-config.yml \
    --path ${CHART} \
    ${CHART_NAME}-${NEW_VERSION}
  git tag -d ${CHART_NAME}-${NEW_VERSION}

  ## Github release chart
  echo "########### Releasing ${CHART_NAME} chart ###########"
  ghr -token "${GITHUB_TOKEN}" \
    -name "${CHART_NAME}-${NEW_VERSION}" \
    -body "$(cat /tmp/${CHART_NAME}-${NEW_VERSION}.md)" \
    -owner "${PROJECT_USERNAME}" \
    -repository "${PROJECT_REPONAME}" \
    -commitish "${COMMIT_SHA}" \
    -replace \
    ${CHART_NAME}-${NEW_VERSION} \
    ${TASK_ROOT}/charts/charts/${CHART_NAME}-${NEW_VERSION}.tgz

done <${TASK_ROOT}/bumping

## Move status pointer
git log --oneline -n 1 --format=%H >status
git add status
git commit -m "chore(status): move status pointer [ci skip]"
