Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Check-LastExit {
    if (-not $?) {
        throw "Previous command failed. Exiting."
    }
}

Write-Output "=== Running restore.ps1 ==="
& .\restore.ps1
Check-LastExit

Write-Output "=== Starting first build process ==="
$dirs = Get-ChildItem -Directory | Where-Object { $_.Name -notmatch '^\.' }
foreach ($dir in $dirs) {
    Write-Output ">>> Configuring and building: $($dir.Name)"
    & xr_cubemx_cfg -d $dir.FullName
    Check-LastExit

    & cmake -S $dir.FullName -B "$($dir.FullName)\build" -G Ninja
    Check-LastExit

    & cmake --build "$($dir.FullName)\build"
    Check-LastExit
}

Write-Output "=== First build complete. Output ELF files: ==="
$files = Get-ChildItem -Recurse -File -Depth 3
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($content.Length -ge 4 -and $content[0] -eq 0x7F -and $content[1] -eq 0x45 -and $content[2] -eq 0x4C -and $content[3] -eq 0x46) {
        Write-Output "`t$($file.FullName)"
    }
}

Write-Output "=== Running restore.ps1 again ==="
& .\restore.ps1
Check-LastExit

Write-Output "=== Starting second build process (with toolchain) ==="
foreach ($dir in $dirs) {
    Write-Output ">>> Configuring and building with toolchain: $($dir.Name)"
    & xr_cubemx_cfg -d $dir.FullName -c
    Check-LastExit

    & cmake $dir.FullName -B"$($dir.FullName)\build" -G Ninja -DCMAKE_TOOLCHAIN_FILE="cmake\gcc-arm-none-eabi.cmake"
    Check-LastExit

    & cmake --build "$($dir.FullName)\build"
    Check-LastExit
}

Write-Output "=== Second build complete. Output ELF files: ==="
$files = Get-ChildItem -Recurse -File -Depth 3
foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($content.Length -ge 4 -and $content[0] -eq 0x7F -and $content[1] -eq 0x45 -and $content[2] -eq 0x4C -and $content[3] -eq 0x46) {
        Write-Output "`t$($file.FullName)"
    }
}

Write-Output "=== All builds done successfully. ==="
