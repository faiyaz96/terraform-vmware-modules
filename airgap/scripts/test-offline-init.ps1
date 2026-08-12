$ErrorActionPreference = "Stop"

$bundleDirectory = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$terraformBinary = Join-Path $bundleDirectory "bin/windows_amd64/terraform.exe"
$providerConfiguration = Join-Path $bundleDirectory "config/provider-test"
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("terraform-airgap-" + [guid]::NewGuid())

New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

try {
    Copy-Item (Join-Path $providerConfiguration "main.tf") $temporaryDirectory
    Copy-Item (Join-Path $providerConfiguration ".terraform.lock.hcl") $temporaryDirectory

    $mirrorPath = (Join-Path $bundleDirectory "provider-mirror").Replace('\', '/')
    $cliTemplate = Get-Content (Join-Path $bundleDirectory "config/terraform-airgap-windows.tfrc.example") -Raw
    $cliConfiguration = Join-Path $temporaryDirectory "terraform.tfrc"
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText(
        $cliConfiguration,
        $cliTemplate.Replace('C:/terraform/provider-mirror', $mirrorPath),
        $utf8WithoutBom
    )

    $env:TF_CLI_CONFIG_FILE = $cliConfiguration
    $env:CHECKPOINT_DISABLE = "1"

    & $terraformBinary "-chdir=$temporaryDirectory" init -backend=false -input=false
    if ($LASTEXITCODE -ne 0) { throw "Offline terraform init failed." }

    & $terraformBinary "-chdir=$temporaryDirectory" providers
    if ($LASTEXITCODE -ne 0) { throw "terraform providers failed." }

    Write-Host "Offline provider initialization succeeded for windows_amd64."
}
finally {
    Remove-Item -Recurse -Force $temporaryDirectory
}
