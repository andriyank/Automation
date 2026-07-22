#!/bin/bash
#
# ============================================================
#  LINUX SYSTEM HEALTH CHECK
# ------------------------------------------------------------
#  Script ini mengecek kondisi kesehatan komputer/server Linux
#  secara otomatis, lalu membuat laporan dalam format HTML
#  yang mudah dibaca oleh siapa saja (tidak perlu paham Linux).
#
#  Cara pakai:
#      bash health_check.sh
#
#  Hasil laporan akan tersimpan di folder "reports/"
#  dengan nama sesuai tanggal & jam.
# ============================================================

# --- Persiapan folder laporan ---
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"

TANGGAL=$(date +"%Y-%m-%d_%H-%M-%S")
TANGGAL_TAMPIL=$(date +"%d %B %Y, %H:%M")
FILE_LAPORAN="$REPORT_DIR/laporan_$TANGGAL.html"

# ============================================================
# FUNGSI BANTUAN
# ============================================================

# Fungsi untuk menentukan status berdasarkan persentase pemakaian
# < 70%  = Sehat (hijau)
# 70-90% = Perlu Perhatian (kuning)
# > 90%  = Bermasalah (merah)
tentukan_status() {
    local persen=$1
    if (( persen < 70 )); then
        echo "SEHAT"
    elif (( persen < 90 )); then
        echo "PERHATIAN"
    else
        echo "BERMASALAH"
    fi
}

warna_status() {
    case "$1" in
        SEHAT) echo "#2ecc71" ;;      # hijau
        PERHATIAN) echo "#f1c40f" ;;  # kuning
        BERMASALAH) echo "#e74c3c" ;; # merah
    esac
}

label_status() {
    case "$1" in
        SEHAT) echo "✅ Sehat" ;;
        PERHATIAN) echo "⚠️ Perlu Perhatian" ;;
        BERMASALAH) echo "❌ Bermasalah" ;;
    esac
}

# ============================================================
# 1. CEK PEMAKAIAN CPU
# ============================================================
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | grep -o '[0-9.]*')
CPU_USAGE=$(printf "%.0f" "$(echo "100 - $CPU_IDLE" | bc 2>/dev/null || echo 0)")
[ -z "$CPU_USAGE" ] && CPU_USAGE=0
STATUS_CPU=$(tentukan_status "$CPU_USAGE")

# ============================================================
# 2. CEK PEMAKAIAN RAM (MEMORY)
# ============================================================
RAM_INFO=$(free -m | awk '/Mem:/ {printf "%d %d %.0f", $3, $2, ($3/$2)*100}')
RAM_USED=$(echo "$RAM_INFO" | awk '{print $1}')
RAM_TOTAL=$(echo "$RAM_INFO" | awk '{print $2}')
RAM_PERSEN=$(echo "$RAM_INFO" | awk '{print $3}')
STATUS_RAM=$(tentukan_status "$RAM_PERSEN")

# ============================================================
# 3. CEK PEMAKAIAN DISK (HARDISK / STORAGE)
# ============================================================
DISK_INFO=$(df -h / | awk 'NR==2 {print $3, $2, $5}' | tr -d '%')
DISK_USED=$(echo "$DISK_INFO" | awk '{print $1}')
DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
DISK_PERSEN=$(echo "$DISK_INFO" | awk '{print $3}')
STATUS_DISK=$(tentukan_status "$DISK_PERSEN")

# ============================================================
# 4. CEK LAMA KOMPUTER MENYALA (UPTIME)
# ============================================================
UPTIME_TEXT=$(uptime -p 2>/dev/null | sed 's/up //')
[ -z "$UPTIME_TEXT" ] && UPTIME_TEXT=$(uptime)

# ============================================================
# 5. CEK PERCOBAAN LOGIN GAGAL (indikasi keamanan sederhana)
# ============================================================
if [ -f /var/log/auth.log ]; then
    LOGIN_GAGAL=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null)
else
    LOGIN_GAGAL="Tidak dapat dicek (log tidak ditemukan)"
fi

if [[ "$LOGIN_GAGAL" =~ ^[0-9]+$ ]]; then
    if (( LOGIN_GAGAL == 0 )); then
        STATUS_LOGIN="SEHAT"
    elif (( LOGIN_GAGAL < 20 )); then
        STATUS_LOGIN="PERHATIAN"
    else
        STATUS_LOGIN="BERMASALAH"
    fi
else
    STATUS_LOGIN="PERHATIAN"
fi

# ============================================================
# KESIMPULAN UMUM (status paling buruk yang menentukan)
# ============================================================
KESIMPULAN="SEHAT"
for s in "$STATUS_CPU" "$STATUS_RAM" "$STATUS_DISK" "$STATUS_LOGIN"; do
    if [ "$s" == "BERMASALAH" ]; then
        KESIMPULAN="BERMASALAH"
        break
    elif [ "$s" == "PERHATIAN" ] && [ "$KESIMPULAN" != "BERMASALAH" ]; then
        KESIMPULAN="PERHATIAN"
    fi
done

# ============================================================
# MEMBUAT LAPORAN HTML
# ============================================================
cat > "$FILE_LAPORAN" << EOF
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Laporan Kesehatan Sistem - $TANGGAL_TAMPIL</title>
<style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background:#f4f6f8; margin:0; padding:0; color:#2c3e50; }
    .container { max-width: 750px; margin: 30px auto; background:#fff; border-radius:10px; box-shadow:0 2px 10px rgba(0,0,0,0.08); overflow:hidden; }
    .header { background:$(warna_status "$KESIMPULAN"); color:#fff; padding:25px 30px; }
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
        <h1>Laporan Kesehatan Sistem</h1>
        <p>Dibuat pada: $TANGGAL_TAMPIL</p>
        <p>Status Keseluruhan: $(label_status "$KESIMPULAN")</p>
    </div>
    <div class="content">
        <table>
            <tr><th>Komponen</th><th>Detail</th><th>Status</th></tr>
            <tr>
                <td>Penggunaan Processor (CPU)</td>
                <td>${CPU_USAGE}% terpakai</td>
                <td><span class="badge" style="background:$(warna_status "$STATUS_CPU")">$(label_status "$STATUS_CPU")</span></td>
            </tr>
            <tr>
                <td>Penggunaan Memori (RAM)</td>
                <td>${RAM_USED} MB dari ${RAM_TOTAL} MB (${RAM_PERSEN}%)</td>
                <td><span class="badge" style="background:$(warna_status "$STATUS_RAM")">$(label_status "$STATUS_RAM")</span></td>
            </tr>
            <tr>
                <td>Penggunaan Penyimpanan (Disk)</td>
                <td>${DISK_USED} dari ${DISK_TOTAL} (${DISK_PERSEN}%)</td>
                <td><span class="badge" style="background:$(warna_status "$STATUS_DISK")">$(label_status "$STATUS_DISK")</span></td>
            </tr>
            <tr>
                <td>Lama Sistem Menyala</td>
                <td>$UPTIME_TEXT</td>
                <td>—</td>
            </tr>
            <tr>
                <td>Percobaan Login Gagal</td>
                <td>$LOGIN_GAGAL kali</td>
                <td><span class="badge" style="background:$(warna_status "$STATUS_LOGIN")">$(label_status "$STATUS_LOGIN")</span></td>
            </tr>
        </table>

        <div class="keterangan">
            <b>Keterangan:</b><br>
            ✅ <b>Sehat</b> = Semua berjalan normal, tidak perlu tindakan.<br>
            ⚠️ <b>Perlu Perhatian</b> = Sebaiknya mulai dipantau, belum darurat.<br>
            ❌ <b>Bermasalah</b> = Perlu tindakan / dihubungi tim IT sesegera mungkin.
        </div>
    </div>
    <div class="footer">
        Laporan dibuat otomatis oleh Linux System Health Check &mdash; tidak memerlukan tindakan manual.
    </div>
</div>
</body>
</html>
EOF

echo ""
echo "=========================================="
echo " Pengecekan selesai!"
echo " Status keseluruhan sistem: $KESIMPULAN"
echo " Laporan tersimpan di: $FILE_LAPORAN"
echo "=========================================="
echo ""
