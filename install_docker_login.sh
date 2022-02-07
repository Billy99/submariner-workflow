#!/bin/bash

# Source the variables in variables.sh
. variables.sh

# Make sure Shipyard directory exists
if [[ -d "${SUBMARINER_BASE_DIRECTORY}/shipyard/" ]] ; then
  # Apply the patch
  echo "Copying \"docker_login.diff\" to \"shipyard/\" and applying ..."
  cp docker_login.diff "${SUBMARINER_BASE_DIRECTORY}/shipyard/."
  pushd "${SUBMARINER_BASE_DIRECTORY}/shipyard/" &>/dev/null
  git apply docker_login.diff
  popd &>/dev/null

  # Update Dockerfile.dapper in all the existing repos
  pushd "${SUBMARINER_BASE_DIRECTORY}" &>/dev/null
  SUBMARINER_REPOS=( $( ls . ) )
  for REPO in "${SUBMARINER_REPOS[@]}"
  do
    if [[ -d ${REPO} ]] ; then
      if [[ "${REPO}" != "shipyard" ]]; then
        echo "Copying \"Dockerfile.dapper\" to \"${REPO}\""
        pushd ${REPO} &>/dev/null
        cp ../shipyard/Dockerfile.dapper . 
        popd &>/dev/null
      fi  
    fi
  done
  popd &>/dev/null  
else
  echo "${SUBMARINER_BASE_DIRECTORY}/shipyard/ does not exist"
fi

