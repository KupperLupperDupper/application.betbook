<#
.SYNOPSIS
    Generate an Android upload keystore for BetBook and print the exact
    commands needed to configure GitHub Actions release signing.

.DESCRIPTION
    Creates a self-signed RSA-2048 keystore valid for ~27 years using keytool
    (bundled with the JDK). It then prints:
      * the base64 command whose output goes into the KEYSTORE_BASE64 secret
      * a reminder of the four GitHub secrets to add
      * a sample android/key.properties for local release builds

    The keystore is written OUTSIDE the repo tree by default and must never be
    committed. Losing it means you can no longer ship updates signed with the
    same key, so back it up somewhere safe (a password manager works well).

.EXAMPLE
    ./scripts/generate-keystore.ps1
    ./scripts/generate-keystore.ps1 -OutFile "$HOME/betbook-upload.jks" -Alias upload
#>
[CmdletBinding()]
param(
    [string]$OutFile = "$HOME/betbook-upload-keystore.jks",
    [string]$Alias   = "upload",
    [int]$ValidityDays = 10000
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Write-Error "keytool not found on PATH. Install a JDK 17 (Temurin) and re-run."
    exit 1
}

if (Test-Path $OutFile) {
    Write-Error "A keystore already exists at '$OutFile'. Refusing to overwrite. Delete it or pass a different -OutFile."
    exit 1
}

Write-Host "==> Generating upload keystore at: $OutFile" -ForegroundColor Cyan
Write-Host "    You will be prompted for a keystore password, a key password," -ForegroundColor DarkGray
Write-Host "    and some optional identity fields (name/org can be left blank)." -ForegroundColor DarkGray
Write-Host ""

# keytool prompts interactively for both passwords and the distinguished name.
keytool -genkeypair `
    -v `
    -keystore $OutFile `
    -alias $Alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity $ValidityDays `
    -storetype JKS

if ($LASTEXITCODE -ne 0) {
    Write-Error "keytool failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "==> Keystore created." -ForegroundColor Green
Write-Host ""
Write-Host "1) Copy the base64 of the keystore into the KEYSTORE_BASE64 secret:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   [Convert]::ToBase64String([IO.File]::ReadAllBytes('$OutFile')) | Set-Clipboard" -ForegroundColor White
Write-Host ""
Write-Host "   (The command above copies it straight to your clipboard. Or write it to a file:)" -ForegroundColor DarkGray
Write-Host "   [Convert]::ToBase64String([IO.File]::ReadAllBytes('$OutFile')) | Out-File -Encoding ascii keystore.base64.txt" -ForegroundColor White
Write-Host ""
Write-Host "2) Add these GitHub repository secrets" -ForegroundColor Yellow
Write-Host "   (Settings -> Secrets and variables -> Actions -> New repository secret):" -ForegroundColor Yellow
Write-Host ""
Write-Host "     KEYSTORE_BASE64      the base64 blob from step 1" -ForegroundColor White
Write-Host "     KEYSTORE_PASSWORD    the keystore password you just chose" -ForegroundColor White
Write-Host "     KEY_PASSWORD         the key password you just chose" -ForegroundColor White
Write-Host "     KEY_ALIAS            $Alias" -ForegroundColor White
Write-Host ""
Write-Host "3) For LOCAL release builds, create android/key.properties (git-ignored):" -ForegroundColor Yellow
Write-Host ""
Write-Host "     storeFile=$OutFile" -ForegroundColor White
Write-Host "     storePassword=<your keystore password>" -ForegroundColor White
Write-Host "     keyAlias=$Alias" -ForegroundColor White
Write-Host "     keyPassword=<your key password>" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: keep '$OutFile' and its passwords safe and OUT of git." -ForegroundColor Red
Write-Host "           If you lose them you cannot update the app with the same signature." -ForegroundColor Red
