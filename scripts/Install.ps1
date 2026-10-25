# Run as the user who will use Cirrus. Only certificate import is elevated.
$ErrorActionPreference = 'Stop'
try {
    $package = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.msix')
    $certificate = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.cer')
    if ($package.Count -ne 1 -or $certificate.Count -ne 1) {
        throw 'Extract the complete installer ZIP before running Install.cmd.'
    }
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificate[0].FullName)
    if ($cert.Subject -ne 'CN=shaklow.Cirrus') { throw 'Unexpected package publisher.' }
    $signature = Get-AuthenticodeSignature -LiteralPath $package[0].FullName
    if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $cert.Thumbprint) {
        throw 'The package signature does not match the included certificate.'
    }
    if (-not (Test-Path "Cert:\LocalMachine\TrustedPeople\$($cert.Thumbprint)")) {
        Write-Host 'Windows will ask permission to trust the certificate for this unofficial Cirrus build.'
        $certPath = $certificate[0].FullName.Replace("'", "''")
        $command = "`$ErrorActionPreference='Stop'; try { Import-Certificate -FilePath '$certPath' -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null; exit 0 } catch { Write-Error `$_; exit 1 }"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $import = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $encoded)
        if ($import.ExitCode -ne 0) { throw 'Certificate installation was not completed.' }
    }
    if ((Get-AuthenticodeSignature -LiteralPath $package[0].FullName).Status -ne 'Valid') {
        throw 'The package signature is invalid. Download the installer again.'
    }
    $parameters = @{ Path = $package[0].FullName }
    $dependencyFolder = Join-Path $PSScriptRoot 'Dependencies'
    if (Test-Path -LiteralPath $dependencyFolder) {
        $dependencies = @(Get-ChildItem -LiteralPath $dependencyFolder -Recurse -File | Where-Object Extension -in '.appx', '.msix')
        if ($dependencies.Count) { $parameters.DependencyPath = [string[]]$dependencies.FullName }
    }
    Add-AppxPackage @parameters
    Write-Host 'Cirrus is installed. Open Cirrus from the Start menu.' -ForegroundColor Green
    Read-Host 'Press Enter to close'
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
