$ErrorActionPreference = "Stop"

Get-ChildItem -Directory | Where-Object { $_.Name -notmatch '^\.' } | ForEach-Object {
    Write-Output "Removing directory: $($_.FullName)"
    Remove-Item -Recurse -Force $_.FullName
}

Write-Output "Restoring git changes..."
& git restore .
& git reset .
& git reset --hard
& git clean -fd

if (Test-Path ".git\modules") {
    Get-ChildItem ".git\modules" | Remove-Item -Recurse -Force
}
