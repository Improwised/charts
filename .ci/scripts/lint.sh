set -ex
TASK_ROOT=$(pwd)
cd repo
[[ "" == $(ct list-changed --config ct.yaml --since $(head -n1 status)) ]] && echo "#### no changes found ####" && exit 0

## Set git user email and name for commit
git config --global user.email concourse@github-noreply.com
git config --global user.name concourse

## This loop is for stopping "Chart version not ok. Needs a version bump!" by ct linting
for chart in $(ct list-changed --config ct.yaml --since $(head -n1 status) 2>/dev/null); do
  CHART_NAME=$(yq e '.name' $chart/Chart.yaml)
  echo "Checking version bump for ${CHART_NAME}"
  COMMIT_MESSAGE=$(git log --format=%B -n 1 $chart/)
  printf "last commit message: \"${COMMIT_MESSAGE}\" \n"
  if [[ ${COMMIT_MESSAGE} =~ ${BUMP_PATTERN} ]]; then
    OLD_VERSION=$(yq e '.version' $chart/Chart.yaml)
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

    ## bump chart and local commit
    ## note: exported NEW_VERSION because yq can use it with `env` operator
    export NEW_VERSION=$(bumpp ${BUMP} ${OLD_VERSION})
    yq eval '.version = env(NEW_VERSION)' $chart/Chart.yaml >$chart/_Chart.yaml
    mv $chart/_Chart.yaml $chart/Chart.yaml

    COMMIT_MSG="${CHART_NAME}: ${OLD_VERSION} → ${NEW_VERSION}"
    git add $chart/Chart.yaml
    git commit -m "${COMMIT_MSG} [ci skip]"
  else
    echo "skipping"
    continue
  fi
done

## ct linting
echo "this is linting task"
export HELM_CONFIG_HOME=./
ct lint --config ct.yaml --since $(head -n1 status) --debug
