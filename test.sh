#!/bin/sh

set -e
find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec sh -c '
    set -e
    for dir in "$@"; do
        libxr_config_cubemx_project -d "$dir"
        cmake "$dir" -B"$dir/build" -G Ninja
        cmake --build "$dir/build"
    done
' _ {} +
