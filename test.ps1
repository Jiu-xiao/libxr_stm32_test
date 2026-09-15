param(
    [string]$Branch = "dev",
    [string[]]$Target = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Check-LastExit {
    if ($LASTEXITCODE -ne 0) {
        throw "Previous command failed. Exiting."
    }
}

function Build-Project($dir, $toolchain, [string[]]$extraArgs = @(), $buildSuffix = "") {
    $buildDir = Join-Path $dir.FullName ("build" + $buildSuffix)
    if (Test-Path $buildDir) {
        Remove-Item -Recurse -Force $buildDir
    }

    # 修正路径分隔符为 /
    $toolchainFile = $null
    if ($toolchain) {
        $toolchainFile = (Join-Path $dir.FullName ("cmake\" + $toolchain)) -replace '\\', '/'
    }

    $cmakeArgs = @(
        "-S", "$($dir.FullName -replace '\\','/')",
        "-B", "$($buildDir -replace '\\','/')",
        "-G", "Ninja"
    )
    if ($toolchainFile) {
        $cmakeArgs += "-DCMAKE_TOOLCHAIN_FILE=$toolchainFile"
    }
    if ($extraArgs.Count -gt 0) {
        $cmakeArgs += $extraArgs
    }

    Write-Output "CMake args: $($cmakeArgs -join ' ')"

    & cmake @cmakeArgs
    Check-LastExit

    & cmake --build "$buildDir"
    Check-LastExit
}

$dirs = if ($Target.Count -gt 0) {
    foreach ($name in $Target) {
        $dir = Get-Item -Path $name -ErrorAction SilentlyContinue
        if (-not $dir -or -not $dir.PSIsContainer) {
            throw "Target directory not found: $name"
        }
        $dir
    }
}
else {
    Get-ChildItem -Directory | Where-Object { $_.Name -notmatch '^\.' -and (Test-Path (Join-Path $_.FullName 'CMakeLists.txt')) }
}

if (-not $dirs) {
    throw "No STM32 target projects found."
}

foreach ($dir in $dirs) {
    Write-Output ">>> Processing: $($dir.Name)"

    & xr_cubemx_cfg -d $dir.FullName
    Check-LastExit

    Push-Location (Join-Path $dir.FullName "Middlewares\Third_Party\LibXR")
    git fetch origin $Branch
    Check-LastExit
    git checkout --detach FETCH_HEAD
    Pop-Location
    Check-LastExit

    # 1. GCC 构建
    Write-Output ">>>> [GCC] Building"
    Build-Project $dir "gcc-arm-none-eabi.cmake" @() "-gcc"

    # 2. Clang 三种配置
    $clangConfigs = @("STARM_HYBRID", "STARM_NEWLIB", "STARM_PICOLIBC")
    foreach ($cfg in $clangConfigs) {
        Write-Output ">>>> [Clang] Config: $cfg"
        $stdlib = switch ($cfg) {
            "STARM_HYBRID" { "--hybrid" }
            "STARM_NEWLIB" { "--newlib" }
            "STARM_PICOLIBC" { "--picolibc" }
        }
        Push-Location $dir.FullName
        try {
            & xr_stm32_toolchain_switch clang $stdlib
            Check-LastExit
        }
        finally {
            Pop-Location
        }
        Build-Project $dir "starm-clang.cmake" @("-DSTARM_TOOLCHAIN_CONFIG=$cfg") ("-clang-$cfg")
    }
}

Write-Output "=== All builds complete. Output ELF files: ==="
$files = Get-ChildItem -Recurse -File -Depth 3
foreach ($file in $files) {
    try {
        $content = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($content.Length -ge 4 -and $content[0] -eq 0x7F -and $content[1] -eq 0x45 -and $content[2] -eq 0x4C -and $content[3] -eq 0x46) {
            Write-Output "`t$($file.FullName)"
        }
    }
    catch {
        # 忽略读取错误
    }
}

Write-Output "=== All builds done successfully. ==="
