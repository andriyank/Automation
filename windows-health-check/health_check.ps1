# ============================================================
#  WINDOWS SYSTEM HEALTH CHECK
# ------------------------------------------------------------
#  This script automatically checks the health of your
#  Windows laptop/PC, then generates a report in HTML format
#  that's easy for anyone to read (no technical knowledge
#  needed).
#
#  How to use:
#      1. Right-click this file -> "Run with PowerShell"
#      or
#      2. Open PowerShell, then run:
#         .\health_check.ps1
#
#  The report will be saved inside the "reports\" folder
#  and will automatically open in your browser.
# ============================================================

# --- Prepare the reports folder ---
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $Dir "reports"
if (!(Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir | Out-Null }

$DateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$DateDisplay = Get-Date -Format "dd MMMM yyyy, HH:mm"
$ReportFile = Join-Path $ReportDir "report_$DateStamp.html"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-Status($percent) {
    if ($percent -lt 70) { return "HEALTHY" }
    elseif ($percent -lt 90) { return "ATTENTION" }
    else { return "PROBLEM" }
}

function Get-StatusColor($status) {
    switch ($status) {
        "HEALTHY" { return "#2ecc71" }
        "ATTENTION" { return "#f1c40f" }
        "PROBLEM" { return "#e74c3c" }
    }
}

function Get-StatusLabel($status) {
    switch ($status) {
        "HEALTHY" { return "&#9989; Healthy" }
        "ATTENTION" { return "&#9888;&#65039; Needs Attention" }
        "PROBLEM" { return "&#10060; Problem" }
    }
}

# ============================================================
# 1. CHECK CPU USAGE
# ============================================================
$CpuUsage = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average)
$StatusCpu = Get-Status $CpuUsage

# ============================================================
# 2. CHECK RAM (MEMORY) USAGE
# ============================================================
$OS = Get-CimInstance Win32_OperatingSystem
$RamTotalMB = [math]::Round($OS.TotalVisibleMemorySize / 1024)
$RamFreeMB  = [math]::Round($OS.FreePhysicalMemory / 1024)
$RamUsedMB  = $RamTotalMB - $RamFreeMB
$RamPercent = [math]::Round(($RamUsedMB / $RamTotalMB) * 100)
$StatusRam  = Get-Status $RamPercent

# ============================================================
# 3. CHECK DISK USAGE (Drive C:)
# ============================================================
$Disk = Get-PSDrive C
$DiskTotalGB = [math]::Round(($Disk.Used + $Disk.Free) / 1GB, 1)
$DiskUsedGB  = [math]::Round($Disk.Used / 1GB, 1)
$DiskPercent = [math]::Round(($Disk.Used / ($Disk.Used + $Disk.Free)) * 100)
$StatusDisk  = Get-Status $DiskPercent

# ============================================================
# 4. CHECK SYSTEM UPTIME
# ============================================================
$BootTime = $OS.LastBootUpTime
$Uptime = (Get-Date) - $BootTime
$UptimeText = "{0} days, {1} hours, {2} minutes" -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes

# ============================================================
# 5. CHECK FAILED LOGIN ATTEMPTS (simple security indicator)
# ============================================================
try {
    $FailedLogins = (Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 500 -ErrorAction Stop).Count
} catch {
    $FailedLogins = $null
}

if ($null -ne $FailedLogins) {
    if ($FailedLogins -eq 0) { $StatusLogin = "HEALTHY" }
    elseif ($FailedLogins -lt 20) { $StatusLogin = "ATTENTION" }
    else { $StatusLogin = "PROBLEM" }
    $FailedLoginsText = "$FailedLogins time(s)"
} else {
    $StatusLogin = "ATTENTION"
    $FailedLoginsText = "Cannot be checked (needs to run as Administrator)"
}

# ============================================================
# OVERALL SUMMARY
# ============================================================
$AllStatuses = @($StatusCpu, $StatusRam, $StatusDisk, $StatusLogin)
if ($AllStatuses -contains "PROBLEM") { $Summary = "PROBLEM" }
elseif ($AllStatuses -contains "ATTENTION") { $Summary = "ATTENTION" }
else { $Summary = "HEALTHY" }

# ============================================================
# GENERATE HTML REPORT
# ============================================================
$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>System Health Report - $DateDisplay</title>
<style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background:#f4f6f8; margin:0; padding:0; color:#2c3e50; }
    .container { max-width: 750px; margin: 30px auto; background:#fff; border-radius:10px; box-shadow:0 2px 10px rgba(0,0,0,0.08); overflow:hidden; }
    .header { background:$(Get-StatusColor $Summary); color:#fff; padding:25px 30px; }
    .header h1 { margin:0; font-size:22px; }
    .header p { margin:5px 0 0; opacity:0.9; }
    .content { padding: 25px 30px; }
    table { width:100%; border-collapse: collapse; margin-top:10px; }
    th, td { text-align:left; padding:12px 10px; border-bottom:1px solid #eee; }
    th { background:#f9fafb; font-size:14px; color:#555; }
    .badge { padding:4px 10px; border-radius:20px; font-size:13px; font-weight:600; color:#fff; display:inline-block; }
    .footer { padding:15px 30px; font-size:12px; color:#999; background:#fafafa; }
    .notes { font-size:13px; color:#666; margin-top:20px; line-height:1.6; }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h1>System Health Report (Windows)</h1>
        <p>Generated on: $DateDisplay</p>
        <p>Overall Status: $(Get-StatusLabel $Summary)</p>
    </div>
    <div class="content">
        <table>
            <tr><th>Component</th><th>Details</th><th>Status</th></tr>
            <tr>
                <td>Processor Usage (CPU)</td>
                <td>${CpuUsage}% used</td>
                <td><span class="badge" style="background:$(Get-StatusColor $StatusCpu)">$(Get-StatusLabel $StatusCpu)</span></td>
            </tr>
            <tr>
                <td>Memory Usage (RAM)</td>
                <td>$RamUsedMB MB of $RamTotalMB MB (${RamPercent}%)</td>
                <td><span class="badge" style="background:$(Get-StatusColor $StatusRam)">$(Get-StatusLabel $StatusRam)</span></td>
            </tr>
            <tr>
                <td>Storage Usage (Drive C:)</td>
                <td>$DiskUsedGB GB of $DiskTotalGB GB (${DiskPercent}%)</td>
                <td><span class="badge" style="background:$(Get-StatusColor $StatusDisk)">$(Get-StatusLabel $StatusDisk)</span></td>
            </tr>
            <tr>
                <td>System Uptime</td>
                <td>$UptimeText</td>
                <td>&mdash;</td>
            </tr>
            <tr>
                <td>Failed Login Attempts</td>
                <td>$FailedLoginsText</td>
                <td><span class="badge" style="background:$(Get-StatusColor $StatusLogin)">$(Get-StatusLabel $StatusLogin)</span></td>
            </tr>
        </table>

        <div class="notes">
            <b>Legend:</b><br>
            &#9989; <b>Healthy</b> = Everything is normal, no action needed.<br>
            &#9888;&#65039; <b>Needs Attention</b> = Should start being monitored, not urgent yet.<br>
            &#10060; <b>Problem</b> = Action needed / contact IT team as soon as possible.
        </div>
    </div>
    <div class="footer">
        Report generated automatically by Windows System Health Check &mdash; no manual action required.
    </div>
</div>
</body>
</html>
"@

$Html | Out-File -FilePath $ReportFile -Encoding utf8

Write-Host ""
Write-Host "=========================================="
Write-Host " Check complete!"
Write-Host " Overall system status: $Summary"
Write-Host " Report saved to: $ReportFile"
Write-Host "=========================================="
Write-Host ""

# Automatically open the report in the default browser
Start-Process $ReportFile
