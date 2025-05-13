#! /usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

set -eEuo pipefail

git fetch --prune --prune-tags

# Default tag if no tags exist
TAG="1.0.0"

echo "Checking if tags exists . . ."
tags=$(git tag)
if [ ! -z "$tags" ]; then
    # Tag exists, bump minor semver
    OLD_TAG=`git tag --sort=v:refname | tail -1`
    echo "Existing tag $OLD_TAG found"
    TAG=`echo $OLD_TAG | awk 'BEGIN{FS="."; OFS="."} { print $1, ($2+1), $3 }'`
fi

echo "Creating tag $TAG . . ."
git config --local user.name "github-actions[bot]"
git config --local user.email "41898282+github-actions[bot]@users.noreply.github.com"
git tag -a $TAG -m "Create tag $TAG"
git push origin $TAG