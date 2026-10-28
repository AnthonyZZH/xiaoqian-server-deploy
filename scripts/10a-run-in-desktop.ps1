# Run a Python script inside the logged-on desktop session from an SSH shell.
# SSH sessions have no desktop: UI Automation and screenshots only work in the interactive session,
# so wrap the script in a one-off interactive scheduled task and wait for it.
param([Parameter(Mandatory)][string]$Script, [int]$WaitSeconds = 60, [string]$User = $env:USERNAME)
$ErrorActionPreference = 'Stop'
$t = 'Xiaoqian-OneOff-' + [IO.Path]::GetFileNameWithoutExtension($Script)
Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
$a = New-ScheduledTaskAction -Execute 'C:\xiaoqian\app\wechat\.venv\Scripts\pythonw.exe' -Argument "-X utf8 `"$Script`"" -WorkingDirectory 'C:\xiaoqian\app\wechat'
$p = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest
Register-ScheduledTask -TaskName $t -Action $a -Principal $p | Out-Null
Start-ScheduledTask -TaskName $t
for ($i = 0; $i -lt $WaitSeconds; $i += 2) { Start-Sleep 2; if ((Get-ScheduledTask -TaskName $t).State -ne 'Running') { break } }
"result: $((Get-ScheduledTaskInfo -TaskName $t).LastTaskResult)"
Unregister-ScheduledTask -TaskName $t -Confirm:$false
