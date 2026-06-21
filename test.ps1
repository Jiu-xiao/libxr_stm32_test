param(
    [string]$Branch = "master",
    [string[]]$Target = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Check-LastExit {
    if (-not $?) {
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

Write-Output "=== Running restore.ps1 ==="
& .\restore.ps1
Check-LastExit

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
    Get-ChildItem -Directory | Where-Object { $_.Name -notmatch '^\.' }
}

foreach ($dir in $dirs) {
    Write-Output ">>> Processing: $($dir.Name)"

    & xr_cubemx_cfg -d $dir.FullName
    Check-LastExit

    Push-Location (Join-Path $dir.FullName "Middlewares\Third_Party\LibXR")
    git checkout $Branch
    Pop-Location
    Check-LastExit

    # 1. GCC 构建
    Write-Output ">>>> [GCC] Building"
    Build-Project $dir "gcc-arm-none-eabi.cmake" @() "-gcc"

    # 2. Clang 三种配置
    $clangConfigs = @("STARM_HYBRID", "STARM_NEWLIB", "STARM_PICOLIBC")
    foreach ($cfg in $clangConfigs) {
        Write-Output ">>>> [Clang] Config: $cfg"
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
