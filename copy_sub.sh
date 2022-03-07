#!/bin/bash

# Source the variables in variables.sh
. variables.sh


SUBMARINER_REPOS=( $( ls . ) )
for REPO in "${SUBMARINER_REPOS[@]}"
do
  if [[ -d ${REPO} ]] ; then
    DIFF_FILE_EXISTED=false

    echo "Evaluating \"${REPO}\":"
    pushd ${REPO} &>/dev/null

    if [[ -f "$SUBMARINER_DIFF_FILENAME" ]]; then
      echo "Remove existing diff file:"
      echo "  rm -f ${SUBMARINER_DIFF_FILENAME}"
      rm -f "${SUBMARINER_DIFF_FILENAME}"

      DIFF_FILE_EXISTED=true
    fi

    echo "Remove any exiting changes:"
    echo "  git checkout ."
    git checkout .

    if [[ "$1" == "update" ]] ; then
      echo "Rebasing as well ..."
      # UPSTREAM will be set to something like origin/devel or upsteam/devel
      UPSTREAM=$(git rev-parse --abbrev-ref devel@{upstream})
      # Strip off the /devel
      REPOSITORY=$(echo "${UPSTREAM}" | awk -F"/" '{print $1}')

      echo "Running:"
      echo "  git fetch ${REPOSITORY}"
      git fetch ${REPOSITORY}

      echo "Running:"
      echo "  git rebase ${UPSTREAM}"
      git rebase ${UPSTREAM}
    fi

    # Apply the latest changes
    scp ${SUBMARINER_USER}@${SUBMARINER_SERVER_IP}:${SUBMARINER_BASE_DIRECTORY}/${REPO}/${SUBMARINER_DIFF_FILENAME} . &>/dev/null
    if [[ $? == 0 ]] ; then
      echo "Found diff file, applying ..."
      git apply ${SUBMARINER_DIFF_FILENAME}
    else
      if [[ "$DIFF_FILE_EXISTED" == "true" ]]; then
        echo "Previously existing diff file found, but none now. Delete images ..."
        remove_repo_images ${REPO}
      else
        echo "No diff file found."
      fi
    fi

    popd &>/dev/null
  else
    echo "Skipping \"${REPO}\"."
  fi
  echo "-----"
done
