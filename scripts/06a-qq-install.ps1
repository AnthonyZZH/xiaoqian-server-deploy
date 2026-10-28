# Verify the SHA256 of the QQ installer you downloaded from the official site, then pass it here.
param([Parameter(Mandatory)][string]$Installer, [Parameter(Mandatory)][string]$ExpectedSha256)
$ErrorActionPreference='Stop'
$installer=$Installer
if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ne $ExpectedSha256) { throw 'qq_hash_mismatch' }
$sig=Get-AuthenticodeSignature -LiteralPath $installer
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch '^CN=Tencent') { throw 'qq_signature_invalid' }
if (Test-Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\QQ') { throw 'qq_already_installed' }
$p=Start-Process -FilePath $installer -ArgumentList '/s' -PassThru
if (-not $p.WaitForExit(180000)) { throw 'qq_installer_timeout_process_not_killed' }
if ($p.ExitCode -ne 0) { throw "qq_installer_failed:$($p.ExitCode)" }
$key='HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\QQ'
if (-not (Test-Path $key)) { throw 'qq_uninstall_registry_missing' }
$reg=Get-ItemProperty $key
Write-Output "qq_installed_displayversion=$($reg.DisplayVersion)"
