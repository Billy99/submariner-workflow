#!/bin/bash

SUBMARINER_USER=${SUBMARINER_USER:-$USER}
SUBMARINER_SERVER_IP=${SUBMARINER_SERVER_IP:-"10.8.125.32"}
SUBMARINER_BASE_DIRECTORY=${SUBMARINER_BASE_DIRECTORY:-"/home/${SUBMARINER_USER}/src/submariner-io"}
SUBMARINER_DIFF_FILENAME="submariner_patch.diff"


# This is similar to `make prune-images` except that `make prune-images`
# deletes EVERYTHING. This just deletes images associated with the given
# input repo. Images "<none>" and "quay.io/submariner/shipyard-dapper-base"
# are left behind because there is noway to determine if they are used by
# another repo or not.
function remove_repo_images() {
  LCL_REPO="$1"

  case $LCL_REPO in

    admiral)
      IMAGE_LIST="admiral"
      ;;

    coastguard)
      IMAGE_LIST="coastguard"
      ;;

    lighthouse)
      IMAGE_LIST="lighthouse-agent|lighthouse-coredns"
      ;;

    shipyard)
      IMAGE_LIST="nettest|shipyard-dapper-base|shipyard-linting"
      ;;

    submariner)
      IMAGE_LIST="submariner-gateway|submariner-globalnet|submariner-networkplugin-syncer|submariner-route-agent"
      ;;

    submariner-operator)
      IMAGE_LIST="submariner-operator|submariner-operator-index"
      ;;

    submariner-website)
      IMAGE_LIST=""
      ;;

    *)
      IMAGE_LIST=""
      ;;
  esac

  # This handles images like:
  # $ docker images
  # REPOSITORY                                     TAG     IMAGE ID       CREATED         SIZE
  # localhost:5000/submariner-operator-index       local   e8cadf267d1f   44 hours ago    37MB
  # quay.io/submariner/submariner-operator-index   dev     e8cadf267d1f   44 hours ago    37MB
  # quay.io/submariner/submariner-operator-index   devel   e8cadf267d1f   44 hours ago    37MB
  if [[ -n "${IMAGE_LIST}" ]]; then
    docker images | grep -E "(${IMAGE_LIST})" | while read IMAGE_NAME TAG IMAGE_ID _; do
      if [ "${TAG}" != "<none>" ]; then
        echo "Running: docker rmi ${IMAGE_NAME}:${TAG}"
        docker rmi "${IMAGE_NAME}":"${TAG}"
      else
        echo "Running: docker rmi ${IMAGE_ID}"
        docker rmi "${IMAGE_ID}"
      fi
    done
  fi

  # This handles images like:
  # $ docker images
  # REPOSITORY                                     TAG     IMAGE ID       CREATED         SIZE
  # :
  # submariner                                     devel   4354944c763c   44 hours ago    953MB
  #
  # Because grepping for `submariner` would delete almost all images.
  IMAGE_ID=$(docker images -q "${LCL_REPO}")
  if [[ -n "${IMAGE_ID}" ]]; then
      echo "Running: docker rmi ${IMAGE_ID}"
      docker rmi "${IMAGE_ID}"
  fi
}
