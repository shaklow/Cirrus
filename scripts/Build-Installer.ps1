param([Parameter(Mandatory)][ValidateSet('x64', 'ARM64')][string]$Platform)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location (Split-Path $PSScriptRoot -Parent)
$version = "0.2.$env:GITHUB_RUN_NUMBER.0"
$rid = "win-$($Platform.ToLowerInvariant())"
$packageRoot = Join-Path $PWD "packages\$Platform"
$staging = Join-Path $PWD "staging\$Platform"
$pfxPath = Join-Path $env:RUNNER_TEMP "Cirrus-$Platform.pfx"
$cert = $null
New-Item -ItemType Directory -Force -Path $packageRoot, $staging, 'dist', 'logs' | Out-Null
try {
    # Optional credentials are embedded in the client, as in the upstream template.
    @{ LastFm = @{ ApiKey = "$env:LASTFM_API_KEY"; ApiSecret = "$env:LASTFM_API_SECRET" } } |
        ConvertTo-Json -Depth 3 | Set-Content src/Cirrus/app.config.json -Encoding utf8

    [xml]$manifest = Get-Content src/Cirrus/Package.appxmanifest -Raw
    $manifest.Package.Identity.Version = $version
    $manifest.Save((Join-Path $PWD 'src/Cirrus/Package.appxmanifest'))

    if ($env:SIGNING_PFX_BASE64) {
        [IO.File]::WriteAllBytes($pfxPath, [Convert]::FromBase64String($env:SIGNING_PFX_BASE64))
        $password = ConvertTo-SecureString -String "$env:SIGNING_PFX_PASSWORD" -AsPlainText -Force
        $cert = Import-PfxCertificate -FilePath $pfxPath -Password $password -CertStoreLocation Cert:\CurrentUser\My
    } else {
        $cert = New-SelfSignedCertificate -Type Custom -Subject 'CN=shaklow.Cirrus' `
            -FriendlyName 'Cirrus unofficial CI signing' -KeyAlgorithm RSA -KeyLength 2048 `
            -HashAlgorithm SHA256 -KeyUsage DigitalSignature -KeyExportPolicy NonExportable `
            -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(3) `
            -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}CA=false')
    }
    if ($cert.Subject -ne $manifest.Package.Identity.Publisher) { throw 'Signing certificate must have subject CN=shaklow.Cirrus.' }
    Export-Certificate -Cert $cert -FilePath (Join-Path $staging 'Cirrus.cer') | Out-Null
    Import-Certificate -FilePath (Join-Path $staging 'Cirrus.cer') -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null

    $buildArgs = @(
        'src/Cirrus/Cirrus.csproj', '/restore', '/m', '/verbosity:minimal',
        '/p:Configuration=Release', "/p:Platform=$Platform", "/p:RuntimeIdentifier=$rid",
        "/p:PublishProfile=win-$Platform.pubxml", '/p:GenerateAppxPackageOnBuild=true',
        '/p:UapAppxPackageBuildMode=SideloadOnly', '/p:AppxBundle=Never',
        '/p:AppxPackageSigningEnabled=true', "/p:PackageCertificateThumbprint=$($cert.Thumbprint)",
        '/p:AppxAutoIncrementPackageRevision=false', '/p:GenerateAppInstallerFile=false',
        "/p:AppxPackageDir=$packageRoot\", '/p:ContinuousIntegrationBuild=true',
        "/flp:logfile=logs\build-$Platform.log;verbosity=normal"
    )
    & msbuild @buildArgs
    if ($LASTEXITCODE -ne 0) { throw "MSBuild failed with exit code $LASTEXITCODE." }
    $packages = @(Get-ChildItem -LiteralPath $packageRoot -Filter '*.msix' -Recurse |
        Where-Object FullName -NotMatch '[\\/]Dependencies[\\/]')
    if ($packages.Count -ne 1) { throw "Expected one MSIX, found $($packages.Count)." }
    $signature = Get-AuthenticodeSignature -LiteralPath $packages[0].FullName
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Thumbprint -ne $cert.Thumbprint) {
        throw "MSIX signature verification failed: $($signature.Status)."
    }
    Copy-Item -LiteralPath $packages[0].FullName -Destination $staging
    $dependencies = Join-Path $packages[0].DirectoryName 'Dependencies'
    if (Test-Path -LiteralPath $dependencies) {
        # Keep only matching/neutral dependency packages, never another architecture.
        $dependencyFiles = @(Get-ChildItem -LiteralPath $dependencies -File -Recurse |
            Where-Object { $_.Extension -in '.appx', '.msix' -and $_.FullName -match "[\\/]($Platform|neutral)[\\/]" })
        if ($dependencyFiles.Count) {
            $dependencyTarget = Join-Path $staging 'Dependencies'
            New-Item -ItemType Directory -Path $dependencyTarget -Force | Out-Null
            $dependencyFiles | Copy-Item -Destination $dependencyTarget
        }
    }
    Copy-Item scripts/Install.cmd, scripts/Install.ps1, LICENSE -Destination $staging
    @"
Cirrus $version - $Platform (unofficial)

Extract this entire ZIP, then double-click Install.cmd.
Accept the Windows permission prompt to trust the included signing certificate.
Open Cirrus from the Start menu after installation.
Windows 11 recommended; minimum Windows 10 build 19041.
.NET and Windows App SDK are included. No developer tools are needed.
No Last.fm scrobbling is available unless the builder provided API credentials.

This is a self-signed build from $env:GITHUB_REPOSITORY, not an official release.
Only the PUBLIC certificate is included. The signing private key is never distributed.
Default CI certificates change between builds; trust the certificate on each update.
Uninstall Cirrus through Windows Settings > Apps.
"@ | Set-Content (Join-Path $staging 'INSTALL.txt') -Encoding utf8
    $zipPath = Join-Path $PWD "dist\Cirrus-$version-$Platform.zip"
    Compress-Archive -Path "$staging\*" -DestinationPath $zipPath -Force
    Get-FileHash -LiteralPath $zipPath -Algorithm SHA256 | Format-List
    "### $Platform installer`n- Version: $version`n- Signature verified: $($cert.Thumbprint)`n" |
        Add-Content $env:GITHUB_STEP_SUMMARY
} finally {
    if (Test-Path -LiteralPath $pfxPath) { Remove-Item -LiteralPath $pfxPath -Force }
    if ($cert) { Remove-Item -LiteralPath "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force }
    if (Test-Path src/Cirrus/app.config.json) { Remove-Item src/Cirrus/app.config.json -Force }
}
