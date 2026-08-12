$ErrorActionPreference = "Stop"

$bundleDirectory = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $bundleDirectory "SHA256SUMS"

if (-not (Test-Path $manifestPath -PathType Leaf)) {
    throw "Bundle manifest not found: $manifestPath"
}

foreach ($line in Get-Content $manifestPath) {
    if ($line -notmatch '^([0-9a-f]{64})  (.+)$') {
        throw "Invalid SHA256SUMS entry: $line"
    }

    $expectedHash = $Matches[1]
    $relativePath = $Matches[2].Replace('/', [IO.Path]::DirectorySeparatorChar)
    $artifactPath = Join-Path $bundleDirectory $relativePath

    if (-not (Test-Path $artifactPath -PathType Leaf)) {
        throw "Bundle artifact is missing: $relativePath"
    }

    $actualHash = (Get-FileHash -Algorithm SHA256 $artifactPath).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "Checksum verification failed: $relativePath"
    }

    Write-Host "$relativePath`: OK"
}

Write-Host "All air-gap bundle checksums are valid."
