<#
.SYNOPSIS
    Generate a private key + CSR for the Apple Distribution certificate.

.DESCRIPTION
    Produces two files in the current directory:
      - distribution.key  (private key — never commit, never share)
      - distribution.csr  (upload to developer.apple.com → Certificates)

.EXAMPLE
    .\scripts\generate-csr.ps1 -Email "you@example.com" -Name "Your Name" -Country "CA"
#>

param(
    [Parameter(Mandatory = $true)] [string] $Email,
    [Parameter(Mandatory = $true)] [string] $Name,
    [Parameter(Mandatory = $false)] [string] $Country = "CA"
)

$openssl = (Get-Command openssl -ErrorAction SilentlyContinue)
if (-not $openssl) {
    Write-Host "openssl not found. Install Git for Windows (https://git-scm.com/download/win) which bundles it, then re-run this script." -ForegroundColor Red
    exit 1
}

Write-Host "Generating private key (distribution.key)..."
& openssl genrsa -out distribution.key 2048
if ($LASTEXITCODE -ne 0) { Write-Host "Failed to generate private key." -ForegroundColor Red; exit 1 }

Write-Host "Generating CSR (distribution.csr)..."
$subject = "/emailAddress=$Email/CN=$Name/C=$Country"
& openssl req -new -key distribution.key -out distribution.csr -subj $subject
if ($LASTEXITCODE -ne 0) { Write-Host "Failed to generate CSR." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  distribution.key   — KEEP SECRET. Do not commit. Do not share."
Write-Host "  distribution.csr   — Upload at https://developer.apple.com/account/resources/certificates/add"
Write-Host ""
Write-Host "After Apple gives you a .cer, follow Step 6 in SETUP.md to build the .p12."
