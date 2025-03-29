#!/bin/sh

./restore.sh

set -e
find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec sh -c '
    set -e
    for dir in "$@"; do
        xr_cubemx_cfg -d "$dir"
        cmake "$dir" -B"$dir/build" -G Ninja
        cmake --build "$dir/build"
    done
' _ {} +

echo "All targets build done."
echo "Output files:"

find . -maxdepth 3 -type f -exec sh -c '
    for file do
        if file "$file" | grep -q "ELF"; then
            echo "\t$file"
        fi
    done
' sh {} +

./restore.sh

set -e
find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec sh -c '
    set -e
    for dir in "$@"; do
        xr_cubemx_cfg -d "$dir" -c
        cmake "$dir" -B"$dir/build" -G Ninja -DCMAKE_TOOLCHAIN_FILE=./cmake/gcc-arm-none-eabi.cmake
        cmake --build "$dir/build"
    done
' _ {} +

echo "All targets build done."
echo "Output files:"

find . -maxdepth 3 -type f -exec sh -c '
    for file do
        if file "$file" | grep -q "ELF"; then
            echo "\t$file"
        fi
    done
' sh {} +
