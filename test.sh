#!/bin/sh

set -e

./restore.sh

echo "==== Batch build (gcc + clang: HYBRID/NEWLIB/PICOLIBC) ===="

for dir in */ ; do
    # 跳过隐藏目录
    [ "${dir#.*}" != "$dir" ] && continue

    dir="${dir%/}"
    echo ">>> Processing $dir"

    cd "$dir"

    xr_cubemx_cfg -d .

    # GCC build
    echo ">>>> [GCC] Building"
    cmake . -B"build-gcc" -G Ninja -DCMAKE_TOOLCHAIN_FILE="cmake/gcc-arm-none-eabi.cmake"
    cmake --build "build-gcc"

    export GCC_TOOLCHAIN_ROOT=/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin
    export CLANG_GCC_CMSIS_COMPILER=/opt/st-arm-clang

    # Clang configs
    for cfg in STARM_HYBRID STARM_NEWLIB STARM_PICOLIBC; do
        echo ">>>> [Clang] Config: $cfg"
        cmake . -B"build-clang-$cfg" -G Ninja -DCMAKE_TOOLCHAIN_FILE="cmake/starm-clang.cmake" -DSTARM_TOOLCHAIN_CONFIG=$cfg
        cmake --build "build-clang-$cfg"
    done

    cd ..
done

echo "==== All builds done. Output ELF files: ===="
find . -maxdepth 3 -type f | while read file; do
    if file "$file" 2>/dev/null | grep -q "ELF"; then
        echo "    $file"
    fi
done
