# ============================================================
#  WINDOWS SYSTEM HEALTH CHECK
# ------------------------------------------------------------
#  Script ini mengecek kondisi kesehatan laptop/PC Windows
#  secara otomatis, lalu membuat laporan HTML yang mudah
#  dibaca oleh siapa saja (tidak perlu paham teknis).
#
#  Cara pakai:
#      1. Klik kanan file ini -> "Run with PowerShell"
#      atau
#      2. Buka PowerShell, lalu jalankan:
#         .\health_check.ps1
#
#  Hasil laporan akan tersimpan di folder "reports\"
#  dan otomatis terbuka di browser.
# ============================================================

# --- Persiapan folder laporan ---
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $Dir "reports"
if (!(Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir | Out-Null }

$Tanggal = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$TanggalTampil = Get-Date -Format "dd MMMM yyyy, HH:mm"
$FileLaporan = Join-Path $ReportDir "laporan_$Tanggal.html"

# ============================================================
# FUNGSI BANTUAN
# ============================================================

function Tentukan-Status($persen) {
    if ($persen -lt 70) { return "SEHAT" }
    elseif ($persen -lt 90) { return "PERHATIAN" }
    else { return "BERMASALAH" }
}

function Warna-Status($status) {
    switch ($status) {
        "SEHAT" { return "#2ecc71" }
        "PERHATIAN" { return "#f1c40f" }
        "BERMASALAH" { return "#e74c3c" }
    }
}

function Label-Status($status) {
    switch ($status) {
        "SEHAT" { return "&#9989; Sehat" }
        "PERHATIAN" { return "&#9888;&#65039; Perlu Perhatian" }
        "BERMASALAH" { return "&#10060; Bermasalah" }
    }
}

# ============================================================
# 1. CEK PEMAKAIAN CPU
# ============================================================
$CpuUsage = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average)
$StatusCpu = Tentukan-Status $CpuUsage

# ============================================================
# 2. CEK PEMAKAIAN RAM (MEMORY)
# ============================================================
$OS = Get-CimInstance Win32_OperatingSystem
$RamTotalMB = [math]::Round($OS.TotalVisibleMemorySize / 1024)
$RamFreeMB  = [math]::Round($OS.FreePhysicalMemory / 1024)
$RamUsedMB  = $RamTotalMB - $RamFreeMB
$RamPersen  = [math]::Round(($RamUsedMB / $RamTotalMB) * 100)
$StatusRam  = Tentukan-Status $RamPersen

# ============================================================
# 3. CEK PEMAKAIAN DISK (Drive C:)
# ============================================================
$Disk = Get-PSDrive C
$DiskTotalGB = [math]::Round(($Disk.Used + $Disk.Free) / 1GB, 1)
$DiskUsedGB  = [math]::Round($Disk.Used / 1GB, 1)
$DiskPersen  = [math]::Round(($Disk.Used / ($Disk.Used + $Disk.Free)) * 100)
$StatusDisk  = Tentukan-Status $DiskPersen

# ============================================================
# 4. CEK LAMA KOMPUTER MENYALA (UPTIME)
# ============================================================
$BootTime = $OS.LastBootUpTime
$Uptime = (Get-Date) - $BootTime
$UptimeText = "{0} hari, {1} jam, {2} menit" -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes

# ============================================================
# 5. CEK PERCOBAAN LOGIN GAGAL (indikasi keamanan sederhana)
# ============================================================
try {
    $LoginGagal = (Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 500 -ErrorAction Stop).Count
} catch {
    $LoginGagal = $null
}

if ($null -ne $LoginGagal) {
    if ($LoginGagal -eq 0) { $StatusLogin = "SEHAT" }
    elseif ($LoginGagal -lt 20) { $StatusLogin = "PERHATIAN" }
    else { $StatusLogin = "BERMASALAH" }
    $LoginGagalText = "$LoginGagal kali"
} else {
    $StatusLogin = "PERHATIAN"
    $LoginGagalText = "Tidak dapat dicek (perlu jalankan sebagai Administrator)"
}

# ============================================================
# KESIMPULAN UMUM
# ============================================================
$SemuaStatus = @($StatusCpu, $StatusRam, $StatusDisk, $StatusLogin)
if ($SemuaStatus -contains "BERMASALAH") { $Kesimpulan = "BERMASALAH" }
elseif ($SemuaStatus -contains "PERHATIAN") { $Kesimpulan = "PERHATIAN" }
else { $Kesimpulan = "SEHAT" }

# ============================================================
# MEMBUAT LAPORAN HTML
# ============================================================
$Html = @"
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Laporan Kesehatan Sistem - $TanggalTampil</title>
<style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background:#f4f6f8; margin:0; padding:0; color:#2c3e50; }
    .container { max-width: 750px; margin: 30px auto; background:#fff; border-radius:10px; box-shadow:0 2px 10px rgba(0,0,0,0.08); overflow:hidden; }
    .header { background:$(Warna-Status $Kesimpulan); color:#fff; padding:25px 30px; }
    .header h1 { margin:0; font-size:22px; }
    .header p { margin:5px 0 0; opacity:0.9; }
    .content { padding: 25px 30px; }
    table { width:100%; border-collapse: collapse; margin-top:10px; }
    th, td { text-align:left; padding:12px 10px; border-bottom:1px solid #eee; }
    th { background:#f9fafb; font-size:14px; color:#555; }
    .badge { padding:4px 10px; border-radius:20px; font-size:13px; font-weight:600; color:#fff; display:inline-block; }
    .footer { padding:15px 30px; font-size:12px; color:#999; background:#fafafa; }
    .keterangan { font-size:13px; color:#666; margin-top:20px; line-height:1.6; }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h1>Laporan Kesehatan Sistem (Windows)</h1>
        <p>Dibuat pada: $TanggalTampil</p>
        <p>Status Keseluruhan: $(Label-Status $Kesimpulan)</p>
    </div>
    <div class="content">
        <table>
            <tr><th>Komponen</th><th>Detail</th><th>Status</th></tr>
            <tr>
                <td>Penggunaan Processor (CPU)</td>
                <td>${CpuUsage}% terpakai</td>
                <td><span class="badge" style="background:$(Warna-Status $StatusCpu)">$(Label-Status $StatusCpu)</span></td>
            </tr>
            <tr>
                <td>Penggunaan Memori (RAM)</td>
                <td>$RamUsedMB MB dari $RamTotalMB MB (${RamPersen}%)</td>
                <td><span class="badge" style="background:$(Warna-Status $StatusRam)">$(Label-Status $StatusRam)</span></td>
            </tr>
            <tr>
                <td>Penggunaan Penyimpanan (Drive C:)</td>
                <td>$DiskUsedGB GB dari $DiskTotalGB GB (${DiskPersen}%)</td>
                <td><span class="badge" style="background:$(Warna-Status $StatusDisk)">$(Label-Status $StatusDisk)</span></td>
            </tr>
            <tr>
                <td>Lama Sistem Menyala</td>
                <td>$UptimeText</td>
                <td>&mdash;</td>
            </tr>
            <tr>
                <td>Percobaan Login Gagal</td>
                <td>$LoginGagalText</td>
                <td><span class="badge" style="background:$(Warna-Status $StatusLogin)">$(Label-Status $StatusLogin)</span></td>
            </tr>
        </table>

        <div class="keterangan">
            <b>Keterangan:</b><br>
            &#9989; <b>Sehat</b> = Semua berjalan normal, tidak perlu tindakan.<br>
            &#9888;&#65039; <b>Perlu Perhatian</b> = Sebaiknya mulai dipantau, belum darurat.<br>
            &#10060; <b>Bermasalah</b> = Perlu tindakan / dihubungi tim IT sesegera mungkin.
        </div>
    </div>
    <div class="footer">
        Laporan dibuat otomatis oleh Windows System Health Check &mdash; tidak memerlukan tindakan manual.
    </div>
</div>
</body>
</html>
"@

$Html | Out-File -FilePath $FileLaporan -Encoding utf8

Write-Host ""
Write-Host "=========================================="
Write-Host " Pengecekan selesai!"
Write-Host " Status keseluruhan sistem: $Kesimpulan"
Write-Host " Laporan tersimpan di: $FileLaporan"
Write-Host "=========================================="
Write-Host ""

# Otomatis buka laporan di browser default
Start-Process $FileLaporan
