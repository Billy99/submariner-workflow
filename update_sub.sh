#!/bin/bash

# Source the variables in variables.sh
. variables.sh

SUBMARINER_REPOS=( $( ls . ) )

for REPO in "${SUBMARINER_REPOS[@]}"
do
  if [[ -d ${REPO} ]] ; then
    echo "Evaluating \"${REPO}\":"
    pushd ${REPO} &>/dev/null

    HEADHASH=$(git rev-parse HEAD)
    UPSTREAMHASH=$(git rev-parse devel@{upstream})
    if [ "${HEADHASH}" == "${UPSTREAMHASH}" ] ; then
      echo "No local changes detected, updating ..."

      # UPSTREAM will be set to something like origin/devel or upstream/devel
      UPSTREAM=$(git rev-parse --abbrev-ref devel@{upstream})
      # Strip off the /devel leaving origin or upstream
      REPOSITORY=$(echo "${UPSTREAM}" | awk -F"/" '{print $1}')

      echo "Running:"
      echo "  git fetch ${REPOSITORY}"
      git fetch ${REPOSITORY}
      if [ $? != 0 ]; then
        echo "  *** Failed for repo \"${REPO}\". ***"
      fi

      echo "Running:"
      echo "  git rebase ${UPSTREAM}"
      git rebase ${UPSTREAM}
      if [ $? != 0 ]; then
        echo "  *** Failed for repo \"${REPO}\". ***"
      fi

      # Since nothing has changed in this repo, delete images associated
      # with repo in case there are local changes.
      echo "Removing all images for \"${REPO}\" ..."
      remove_repo_images "${REPO}"

    else
      echo "  *** Project \"${REPO}\" has local changes, manual updating required! ***"
    fi
    popd &>/dev/null
  else
    echo "Skipping \"${REPO}\"."
  fi
  echo "-----"
done

