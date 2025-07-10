#!/bin/sh

set -e

./restore.sh

echo "==== Batch build (gcc + clang: HYBRID/NEWLIB/PICOLIBC) ===="

for dir in */ ; do
    # 跳过隐藏目录
    [ "${dir#.*}" != "$dir" ] && continue

    dir="${dir%/}"
    echo ">>> Processing $dir"

    xr_cubemx_cfg -d "$dir"

    # GCC build
    echo ">>>> [GCC] Building"
    cmake "$dir" -B"$dir/build-gcc" -G Ninja -DCMAKE_TOOLCHAIN_FILE="$dir/cmake/gcc-arm-none-eabi.cmake"
    cmake --build "$dir/build-gcc"

    # Clang configs
    for cfg in STARM_HYBRID STARM_NEWLIB STARM_PICOLIBC; do
        echo ">>>> [Clang] Config: $cfg"
        cmake "$dir" -B"$dir/build-clang-$cfg" -G Ninja -DCMAKE_TOOLCHAIN_FILE="$dir/cmake/starm-clang.cmake" -DSTARM_TOOLCHAIN_CONFIG=$cfg
        cmake --build "$dir/build-clang-$cfg"
    done
done

echo "==== All builds done. Output ELF files: ===="
find . -maxdepth 3 -type f | while read file; do
    if file "$file" 2>/dev/null | grep -q "ELF"; then
        echo "    $file"
    fi
done
