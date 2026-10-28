# Every 5 minutes, restart the WeChat panel if it is not running (it starts replying on its own).
# Runs in the logged-on desktop session: the panel needs a desktop to read WeChat.
param([string]$User = $env:USERNAME)
$ErrorActionPreference = 'Stop'
Copy-Item (Join-Path $PSScriptRoot '09a-run_panel.py') 'C:\xiaoqian\app\run_panel.py' -Force
Copy-Item (Join-Path $PSScriptRoot '09b-panel-watchdog.ps1') 'C:\xiaoqian\app\panel-watchdog.ps1' -Force
New-Item -ItemType Directory -Force C:\xiaoqian\data\ops | Out-Null
$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\xiaoqian\app\panel-watchdog.ps1'
$t = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
$p = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest
$s = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'Xiaoqian-PanelWatchdog' -Action $a -Trigger $t -Principal $p -Settings $s -Force | Out-Null
(Get-ScheduledTask -TaskName 'Xiaoqian-PanelWatchdog').State
