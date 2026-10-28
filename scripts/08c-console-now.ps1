# Move the desktop session to the console right now (e.g. a phone RDP client went to background and
# the screen stopped rendering). The RDP client gets disconnected; the session keeps running.
param([int]$SessionId = 0)
$ErrorActionPreference = 'Stop'
if (-not $SessionId) {
    $line = (quser.exe 2>$null) | Where-Object { $_ -match "^\s*>?$env:USERNAME\s+\S*\s+(\d+)\s" } | Select-Object -First 1
    if (-not $line) { $line = (quser.exe 2>$null) | Where-Object { $_ -match "^\s*>?$env:USERNAME\s+(\d+)\s" } | Select-Object -First 1 }
    $SessionId = [int]([regex]::Match($line, '\s(\d+)\s').Groups[1].Value)
}
$t = 'Xiaoqian-TsconNow'
Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
$a = New-ScheduledTaskAction -Execute 'tscon.exe' -Argument "$SessionId /dest:console"
$p = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName $t -Action $a -Principal $p | Out-Null
Start-ScheduledTask -TaskName $t; Start-Sleep 5
Unregister-ScheduledTask -TaskName $t -Confirm:$false
quser.exe
