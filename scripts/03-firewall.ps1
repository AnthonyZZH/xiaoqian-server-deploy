# Turn Windows Firewall on with allow-by-default, so that outbound BLOCK rules (step 05) take effect.
# Inbound exposure is controlled by the cloud security group (3389/22 from your own IP only).
$ErrorActionPreference = 'Stop'
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True -DefaultInboundAction Allow -DefaultOutboundAction Allow
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
