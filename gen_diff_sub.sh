#!/bin/bash

# Source the variables in variables.sh
. variables.sh

SUBMARINER_REPOS=( $( ls . ) )
for REPO in "${SUBMARINER_REPOS[@]}"
do
  if [[ -d ${REPO} ]] ; then
    echo "Evaluating \"${REPO}\":"
    pushd ${REPO} &>/dev/null

    echo "Remove existing diff file: `rm -f ${SUBMARINER_DIFF_FILENAME}`"
    rm -f "${SUBMARINER_DIFF_FILENAME}"

    HEADHASH=$(git rev-parse HEAD)
    UPSTREAMHASH=$(git rev-parse devel@{upstream})
    if [ "$HEADHASH" != "$UPSTREAMHASH" ] ; then
        HEAD_CNT=$(git log --all --not devel | grep -c "Signed-off-by:")
        HEAD_STR="HEAD"
        for ((i=0; i<$HEAD_CNT; i++)); do HEAD_STR+="^"; done
        echo "Changes detect, regenerate diff file: ${SUBMARINER_DIFF_FILENAME} from \"git diff $HEAD_STR\""
        git diff $HEAD_STR > "${SUBMARINER_DIFF_FILENAME}"
    elif [[ `git status --porcelain` ]]; then
        echo "Changes detect, regenerate diff file: ${SUBMARINER_DIFF_FILENAME} from \"git diff\""
        git diff > "${SUBMARINER_DIFF_FILENAME}"
    fi

    popd &>/dev/null
  else
    echo "Skipping \"${REPO}\"."
  fi
  echo "-----"
done


