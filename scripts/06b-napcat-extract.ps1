# Verify the SHA256 of the NapCat Shell zip you downloaded from the official site, then pass it here.
param([Parameter(Mandatory)][string]$Installer, [Parameter(Mandatory)][string]$ExpectedSha256)
$ErrorActionPreference='Stop'
$zip=$Installer
$target='C:\xiaoqian\app\napcat'
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $ExpectedSha256) { throw 'napcat_hash_mismatch' }
if (@(Get-ChildItem -Force -LiteralPath $target).Count -ne 0) { throw 'napcat_directory_not_empty' }
Expand-Archive -LiteralPath $zip -DestinationPath $target
if (-not (Test-Path -LiteralPath (Join-Path $target 'launcher.bat'))) { throw 'napcat_launcher_missing' }
Write-Output 'napcat_shell_extracted_not_started'
