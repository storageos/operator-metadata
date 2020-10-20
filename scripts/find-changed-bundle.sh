#!/usr/bin/env bash

set -e

# This script tries to identified the versioned bundle changed in a pull
# request. This can be used to run tests against a specific versioned bundle.
# Based on operator-framework community-operator CI setup:
#   https://github.com/operator-framework/community-operators/blob/d1db9ac3bb8b8e241baf66fcab108d37c9caf407/scripts/ci/ansible-env

unset BUNDLE_PATH
unset BUNDLE_VER

PR_COMMIT=$(git log -n1 --format=format:"%H" | tail -n 1)

for file in $(git log -m -1 --name-only --first-parent $PR_COMMIT --name-only 2>&1); do
	if echo "$file" | grep -q "^storageos2"; then
		# Bundle paths are three level deep: storageos2/<version>/metadata/...
		if [ $(echo $file| awk -F'/' '{print NF}') -ge 3 ]; then
			BUNDLE_VER="$(echo "$file" | awk -F'/' '{ print $2 }')"
			BUNDLE_PATH="$(echo "$file" | awk -F'/' '{ print $1"/"$2 }')"
		fi
	fi
done

if [ -z $BUNDLE_VER ]; then
	echo "Could not find bundle version"
	exit 1
fi

echo "Changed bundle version $BUNDLE_VER"
