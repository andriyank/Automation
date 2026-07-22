# ============================================================
#  AUTOMATED SETUP - Windows System Health Check
# ------------------------------------------------------------
#  This script schedules "health_check.ps1" to run
#  AUTOMATICALLY every day at 08:00 AM, so you don't need
#  to run it manually every day.
#
#  IMPORTANT: Run this file by right-clicking it ->
#             "Run with PowerShell as Administrator"
# ============================================================

$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $Dir "health_check.ps1"
$TaskName = "LinuxLabHealthCheck"

if (!(Test-Path $ScriptPath)) {
    Write-Host "Failed: health_check.ps1 not found in this folder." -ForegroundColor Red
    exit
}

$Action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM

$Existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($Existing) {
    Write-Host "Automated scheduling already exists. No changes made." -ForegroundColor Yellow
} else {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Description "Daily system health check" | Out-Null
    Write-Host "Success! From now on, the check will run automatically every day at 08:00 AM." -ForegroundColor Green
    Write-Host "Reports will appear in: $Dir\reports\"
}
