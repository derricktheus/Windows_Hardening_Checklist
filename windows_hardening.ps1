Write-Host "Running My Windows Hardening Checks..." -ForegroundColor Cyan

# Firewall
Write-Host "`n[Firewall] Profiles" -ForegroundColor Yellow
Get-NetFirewallProfile | Format-Table Name, Enabled

# SMBv1
Write-Host "`n[SMBv1] Optional Feature" -ForegroundColor Yellow
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Format-Table FeatureName, State

# Password Policy (export + grep)
Write-Host "`n[Password Policy] Exporting local security policy to C:\Temp\secpol.cfg" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null
secedit /export /cfg C:\Temp\secpol.cfg | Out-Null
Select-String -Path C:\Temp\secpol.cfg -Pattern "MinimumPasswordLength|PasswordComplexity|LockoutBadCount"

# BitLocker
Write-Host "`n[BitLocker] Volume Status" -ForegroundColor Yellow
try {
    Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, ProtectionStatus
} catch {
    Write-Host "BitLocker module not available" -ForegroundColor DarkYellow
}

# Windows Update
Write-Host "`n[Windows Update] Service Status" -ForegroundColor Yellow
Get-Service -Name wuauserv | Select-Object Name, Status, StartType

# RDP
Write-Host "`n[RDP] Remote Desktop Settings" -ForegroundColor Yellow
$rdp = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -ErrorAction SilentlyContinue
if ($rdp) {
    if ($rdp.fDenyTSConnections -eq 1) { Write-Host "RDP: Disabled" }
    else { Write-Host "RDP: Enabled - ensure NLA + firewall scoping" -ForegroundColor DarkYellow }
} else {
    Write-Host "RDP registry key not found"
}

# TLS 1.0
Write-Host "`n[TLS] Check TLS 1.0 (should be disabled)" -ForegroundColor Yellow
$base = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
if (Test-Path $base) {
    $enabled = (Get-ItemProperty -Path $base -Name Enabled -ErrorAction SilentlyContinue).Enabled
    if ($enabled -eq 0) { Write-Host "TLS 1.0: Disabled" }
    else { Write-Host "TLS 1.0: Enabled - consider disabling" -ForegroundColor DarkYellow }
} else {
    Write-Host "TLS 1.0 server key not present (likely disabled)"
}

Write-Host "`nDone." -ForegroundColor Green
