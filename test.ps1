param(
    [string]$Branch = "master"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Check-LastExit {
    if (-not $?) {
        throw "Previous command failed. Exiting."
    }
}

function Build-Project($dir, $toolchain, $extraArgs = "", $buildSuffix = "") {
    $buildDir = "$($dir.FullName)\build$buildSuffix"
    if (Test-Path $buildDir) {
        Remove-Item -Recurse -Force $buildDir
    }

    $cmakeArgs = @(
        "-S", "$($dir.FullName)",
        "-B", "$buildDir",
        "-G", "Ninja"
    )
    if ($toolchain) {
        $toolchainFile = Join-Path $dir.FullName "cmake\$toolchain"
        $cmakeArgs += "-DCMAKE_TOOLCHAIN_FILE=$toolchainFile"
    }
    if ($extraArgs) {
        # 支持多参数（如 -DXXX -DFOO=BAR），自动分割
        $cmakeArgs += $extraArgs -split ' '
    }

    Write-Output "CMake args: $cmakeArgs"
    & cmake @cmakeArgs
    Check-LastExit

    & cmake --build "$buildDir"
    Check-LastExit
}

Write-Output "=== Running restore.ps1 ==="
& .\restore.ps1
Check-LastExit

$dirs = Get-ChildItem -Directory | Where-Object { $_.Name -notmatch '^\.' }
foreach ($dir in $dirs) {
    Write-Output ">>> Processing: $($dir.Name)"

    & xr_cubemx_cfg -d $dir.FullName
    Check-LastExit

    Push-Location "$($dir.FullName)\Middlewares\Third_Party\LibXR"
    git checkout $Branch
    Pop-Location
    Check-LastExit

    # 1. GCC 构建
    Write-Output ">>>> [GCC] Building"
    Build-Project $dir "gcc-arm-none-eabi.cmake" "" "-gcc"

    # 2. Clang 三种配置
    $clangConfigs = @("STARM_HYBRID", "STARM_NEWLIB", "STARM_PICOLIBC")
    foreach ($cfg in $clangConfigs) {
        Write-Output ">>>> [Clang] Config: $cfg"
        Build-Project $dir "starm-clang.cmake" "-DSTARM_TOOLCHAIN_CONFIG=$cfg" "-clang-$cfg"
    }
}

Write-Output "=== All builds complete. Output ELF files: ==="
$files = Get-ChildItem -Recurse -File -Depth 3
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($content.Length -ge 4 -and $content[0] -eq 0x7F -and $content[1] -eq 0x45 -and $content[2] -eq 0x4C -and $content[3] -eq 0x46) {
        Write-Output "`t$($file.FullName)"
    }
}

Write-Output "=== All builds done successfully. ==="
