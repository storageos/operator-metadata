#!/usr/bin/env bash

set -e

# This script takes a package name and lists all the bundle versions in the
# package.

PACKAGE_NAME=${1:-"storageos2"}

declare -a VERSIONS

for path in $(ls -d $PACKAGE_NAME/*/); do
	VER="$(echo "$path" | awk -F'/' '{ print $2 }')"
	VERSIONS+=($VER)
done

echo "${VERSIONS[@]}"
