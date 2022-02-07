#!/bin/bash

# Source the variables in variables.sh
. variables.sh

SUBMARINER_REPOS=(
  admiral
  coastguard
  lighthouse
  shipyard
  submariner
  submariner-operator
  submariner-website
)

SUBMARINER_DEPLOY="local"
if [[ ! -z $1 ]]; then
  if [[ "$1" == "local" ]]; then
    SUBMARINER_DEPLOY="local"
  elif [[ "$1" == "remote" ]]; then
    SUBMARINER_DEPLOY="remote"
  else
    echo "Invalid input: $1"
    echo "Only supported values are \"local\" or \"remote\""
    exit 1
  fi
fi

# Setup Submariner directory
mkdir -p ${SUBMARINER_BASE_DIRECTORY}

echo "Deployment mode: $SUBMARINER_DEPLOY"
echo "Copying scripts ..."
if [[ "${SUBMARINER_DEPLOY}" == "local"  ]] ; then
  cp gen_diff_sub.sh ${SUBMARINER_BASE_DIRECTORY}/.
  cp update_sub.sh ${SUBMARINER_BASE_DIRECTORY}/.
  cp variables.sh ${SUBMARINER_BASE_DIRECTORY}/.
elif [[ "${SUBMARINER_DEPLOY}" == "remote"  ]] ; then
  cp copy_sub.sh ${SUBMARINER_BASE_DIRECTORY}/.
  cp variables.sh ${SUBMARINER_BASE_DIRECTORY}/.
fi

pushd ${SUBMARINER_BASE_DIRECTORY} &>/dev/null

echo "Cloning repositories ..."
for REPO in "${SUBMARINER_REPOS[@]}"
do
  if [[ -d ${REPO} ]] ; then
    echo "Directory \"${REPO}\" already exists."
  else
    echo "git clone https://github.com/submariner-io/${REPO}.git"
    git clone https://github.com/submariner-io/${REPO}.git
  fi
  echo "-----"
done

popd &>/dev/null
