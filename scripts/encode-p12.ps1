<#
.SYNOPSIS
    Base64-encode a .p12 certificate file for use as a GitHub secret.

.EXAMPLE
    .\scripts\encode-p12.ps1 -InputFile distribution.p12 -OutputFile distribution.p12.b64
#>

param(
    [Parameter(Mandatory = $true)] [string] $InputFile,
    [Parameter(Mandatory = $false)] [string] $OutputFile = "distribution.p12.b64"
)

if (-not (Test-Path $InputFile)) {
    Write-Host "File not found: $InputFile" -ForegroundColor Red
    exit 1
}

$bytes = [IO.File]::ReadAllBytes((Resolve-Path $InputFile))
$encoded = [Convert]::ToBase64String($bytes)
Set-Content -NoNewline -Path $OutputFile -Value $encoded

Write-Host "Wrote $OutputFile ($($encoded.Length) chars)." -ForegroundColor Green
Write-Host "Paste its full contents into the GitHub secret named DIST_CERTIFICATE_P12."
