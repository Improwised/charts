set -ex
TASK_ROOT=$(pwd)
cd repo
[[ $(ct list-changed --config ct.yaml --since $(head -n1 status) 2>/dev/null) == *"charts/"* ]] || echo "#### no changes found ####" && exit 0

# function git_fetch() {
#   if [[ $(git config --get remote.origin.url) == *"git@github.com"* ]]; then
#     mkdir -p ~/.ssh
#     touch ~/.ssh/id_rsa ~/.ssh/known_hosts
#     echo $KEY | base64 -d >~/.ssh/id_rsa
#     chmod 600 ~/.ssh/id_rsa
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

## Insatll YQ
source <(curl -s https://raw.githubusercontent.com/pratikbalar/bash-functions/main/functions.sh)
tarr https://github.com/mikefarah/yq/releases/download/v4.9.3/yq_linux_386.tar.gz yq_linux_386 /usr/bin/yq

# locked version at v3.2.0
wget -nv -O /usr/bin/semvertool https://raw.githubusercontent.com/fsaintjacques/semver-tool/20028cb53f340a300b460b423e43f0eac13bcd9a/src/semver
chmod +x /usr/bin/semvertool

BUMP_PATTERN='^(BREAKING[\-\ ]CHANGE|feat|fix|refactor|perf)(\(.+\))?(!)?'
MAJOR='(^.+!|.*BREAKING[\-\ ]CHANGE)'
MINOR='(^feat)'
PATCH='(^fix|^perf|^refactor)'

bumpp() {
  semvertool bump $1 $2
}

## Chart version bumping loop
for chart in $(ct list-changed --config ct.yaml --since $(head -n1 status) 2>/dev/null); do
  CHART_NAME=$(yq e '.name' $chart/Chart.yaml)
  CHARTS=()
  CHARTS+=(${chart})
  echo "Checking version bump for ${CHART_NAME}"
  COMMIT_MESSAGE=$(git log --format=%B -n 1 $chart/)
  printf "last commit message: \"${COMMIT_MESSAGE}\" \n"
  if [[ ${COMMIT_MESSAGE} =~ ${BUMP_PATTERN} ]]; then
    OLD_VERSION=$(yq e '.version' $chart/Chart.yaml)
    CHARTS+=(${OLD_VERSION})
    if [[ ${COMMIT_MESSAGE} =~ ${MAJOR} ]]; then
      BUMP="major"
      echo "Bumping ${BUMP}"
    elif [[ ${COMMIT_MESSAGE} =~ ${MINOR} ]]; then
      BUMP="minor"
      echo "Bumping ${BUMP}"
    elif [[ ${COMMIT_MESSAGE} =~ ${PATCH} ]]; then
      BUMP="patch"
      echo "Bumping ${BUMP}"
    else
      echo "${CHART_NAME}: skipping"
      continue
    fi

    ## mv bump chart and local commit
    ## note: exported NEW_VERSION var so yq can use it with `env` operator
    export NEW_VERSION=$(bumpp ${BUMP} ${OLD_VERSION})
    yq eval '.version = env(NEW_VERSION)' $chart/Chart.yaml >$chart/_Chart.yaml
    mv $chart/_Chart.yaml $chart/Chart.yaml

    ## Commit new chart version
    COMMIT_MSG="bump: ${CHART_NAME}:- ${OLD_VERSION} → ${NEW_VERSION} [ci skip]"
    CHARTS+=(${NEW_VERSION})
    echo ${COMMIT_MSG}
    git add $chart/Chart.yaml
    git commit -m "${COMMIT_MSG}"

    ## add new SHA to array
    COMMIT_SHA=$(git log --oneline -n 1 --format=%H)
    CHARTS+=(${COMMIT_SHA})
    echo ${CHARTS[*]} >>status
    unset CHARTS
  else
    echo "Not bumpable commits found, skipping"
    continue
  fi
done

## Add and commit modified status
git add status
git commit -m "chore(status): modify status pointer [ci skip]"
