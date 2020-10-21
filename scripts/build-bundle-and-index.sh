#!/usr/bin/env bash

set -e

# This script gets the list of all the bundle versions, builds bundle images
# for all the versions and builds an index image using all the bundle images.

source scripts/list-all-versions.sh

# Refer: https://stackoverflow.com/a/17841619
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/$d}"; }

BUNDLE_IMAGE_NAME=storageos/operator-bundle
INDEX_IMAGE_NAME=storageos/operator-index

echo "Bundles versions: ${VERSIONS[@]}"

declare -a IMAGES

echo "Building versioned bundles..."
for ver in ${VERSIONS[@]}; do
	echo "Processing bundle $ver"
	IMG=$BUNDLE_IMAGE_NAME:v$ver
	IMAGES+=($IMG)
	make bundle-build BUNDLE_VERSION=$ver
	docker push $IMG
done

INDEX_BUNDLES=$(join_by , "${IMAGES[@]}")

echo "Building catalog index image..."
make index-build INDEX_BUNDLES=$INDEX_BUNDLES INDEX_VERSION=develop
docker push $INDEX_IMAGE_NAME:develop
