#!/bin/bash

set -e

find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 | while IFS= read -r -d '' dir; do
    rm -rf "$dir"
done

# 还原 git 变更
git restore .
git reset .
