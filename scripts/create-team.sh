#!/usr/bin/env bash

set -o errexit

: ${1?"Usage: $0 <TEAM NAME>"}
if [ -z "$2" ] ; then
	CLUSTER_TYPE="cluster"
else
	if [ ! -d "${REPO_ROOT}/$2" ]; then
		echo "no cluster type $2, exiting"
		exit 1
	fi
	CLUSTER_TYPE="$2"
fi

TEAM_NAME=$1
TEMPLATE="idp"
REPO_ROOT=$(git rev-parse --show-toplevel)
TEAM_DIR="${REPO_ROOT}/$CLUSTER_TYPE/${TEAM_NAME}/"

mkdir -p ${TEAM_DIR}

cp -r "${REPO_ROOT}/$CLUSTER_TYPE/${TEMPLATE}/." ${TEAM_DIR}

for f in ${TEAM_DIR}*.yaml
do
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/$TEMPLATE/$TEAM_NAME/g" ${f}
  else
    sed -i "s/$TEMPLATE/$TEAM_NAME/g" ${f}
  fi
done

echo "${TEAM_NAME} created at ${TEAM_DIR}"
echo "  - ./${TEAM_NAME}/" >> "${REPO_ROOT}/$CLUSTER_TYPE/kustomization.yaml"
echo "${TEAM_NAME} added to ${REPO_ROOT}/$CLUSTER_TYPE/kustomization.yaml"
