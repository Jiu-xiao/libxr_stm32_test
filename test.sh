#!/bin/sh

set -e

# 支持传 branch 和 target 参数，默认 branch=dev 且构建全部板子。
branch="dev"
if [ $# -ge 1 ]; then
    branch="$1"
    shift
fi

targets="$*"

select_dirs() {
    if [ -n "$targets" ]; then
        for target in $targets; do
            if [ ! -d "$target" ]; then
                echo "Target directory not found: $target" >&2
                exit 1
            fi
            printf '%s\n' "$target"
        done
    else
        for dir in */ ; do
            [ "${dir#.*}" != "$dir" ] && continue
            [ -f "$dir/CMakeLists.txt" ] || continue
            printf '%s\n' "${dir%/}"
        done
    fi
}


echo "==== Batch build (gcc + clang: HYBRID/NEWLIB/PICOLIBC) ===="

selected_dirs=$(select_dirs)
if [ -z "$selected_dirs" ]; then
    echo "No STM32 target projects found." >&2
    exit 1
fi
printf '%s\n' "$selected_dirs" | while IFS= read -r dir; do
    echo ">>> Processing $dir"

    cd "$dir"

    xr_cubemx_cfg -d .

    # ===== 切换 LibXR 到目标分支 =====
    libxr_dir="Middlewares/Third_Party/LibXR"
    echo ">>>> [Git] LibXR: checkout $branch"
    (cd "$libxr_dir" && git fetch origin "$branch" && git checkout --detach FETCH_HEAD)

    # GCC build
    echo ">>>> [GCC] Building"
    cmake . -B"build-gcc" -G Ninja -DCMAKE_TOOLCHAIN_FILE="cmake/gcc-arm-none-eabi.cmake"
    cmake --build "build-gcc"

    export GCC_TOOLCHAIN_ROOT=/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin
    export CLANG_GCC_CMSIS_COMPILER=/opt/st-arm-clang

    # Clang configs
    for cfg in STARM_HYBRID STARM_NEWLIB STARM_PICOLIBC; do
        echo ">>>> [Clang] Config: $cfg"
        case "$cfg" in
            STARM_HYBRID) stdlib=--hybrid ;;
            STARM_NEWLIB) stdlib=--newlib ;;
            STARM_PICOLIBC) stdlib=--picolibc ;;
        esac
        xr_stm32_toolchain_switch clang "$stdlib"
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
