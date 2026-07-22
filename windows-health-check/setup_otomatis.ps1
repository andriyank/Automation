# ============================================================
#  SETUP OTOMATIS - Windows System Health Check
# ------------------------------------------------------------
#  Script ini akan menjadwalkan "health_check.ps1" agar berjalan
#  SENDIRI setiap hari jam 08:00 pagi, tanpa perlu dijalankan
#  manual setiap hari.
#
#  PENTING: Jalankan file ini dengan klik kanan -> 
#           "Run with PowerShell as Administrator"
# ============================================================

$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $Dir "health_check.ps1"
$TaskName = "LinuxLabHealthCheck"

if (!(Test-Path $ScriptPath)) {
    Write-Host "Gagal: file health_check.ps1 tidak ditemukan di folder ini." -ForegroundColor Red
    exit
}

$Action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM

$Existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($Existing) {
    Write-Host "Penjadwalan otomatis sudah ada sebelumnya. Tidak ada perubahan." -ForegroundColor Yellow
} else {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Description "Cek kesehatan sistem harian" | Out-Null
    Write-Host "Berhasil! Mulai sekarang, pengecekan akan berjalan otomatis setiap hari jam 08:00 pagi." -ForegroundColor Green
    Write-Host "Laporan akan muncul di folder: $Dir\reports\"
}
