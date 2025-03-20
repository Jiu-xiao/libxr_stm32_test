$ErrorActionPreference = "Stop"

Get-ChildItem -Directory | Where-Object { $_.Name -notmatch '^\.' } | ForEach-Object {
    Write-Output "Removing directory: $($_.FullName)"
    Remove-Item -Recurse -Force $_.FullName
}

Write-Output "Restoring git changes..."
& git restore .
& git reset .
