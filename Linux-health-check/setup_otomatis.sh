#!/bin/bash
#
# ============================================================
#  SETUP OTOMATIS - Linux System Health Check
# ------------------------------------------------------------
#  Script ini akan menjadwalkan "health_check.sh" agar berjalan
#  SENDIRI setiap hari jam 08:00 pagi, tanpa perlu dijalankan
#  manual setiap hari.
#
#  Cara pakai:
#      bash setup_otomatis.sh
# ============================================================

# Cari lokasi folder project ini secara otomatis
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/health_check.sh"
LOG="$DIR/reports/log_otomatis.txt"

if [ ! -f "$SCRIPT" ]; then
    echo "❌ File health_check.sh tidak ditemukan di folder ini."
    exit 1
fi

# Baris perintah yang akan dijadwalkan (setiap hari jam 08:00)
BARIS_CRON="0 8 * * * cd $DIR && bash $SCRIPT >> $LOG 2>&1"

# Cek apakah baris ini sudah pernah ditambahkan sebelumnya, agar tidak dobel
if crontab -l 2>/dev/null | grep -qF "$SCRIPT"; then
    echo "ℹ️  Penjadwalan otomatis sudah ada sebelumnya. Tidak ada perubahan."
else
    ( crontab -l 2>/dev/null; echo "$BARIS_CRON" ) | crontab -
    echo "✅ Berhasil! Mulai sekarang, pengecekan akan berjalan otomatis"
    echo "   setiap hari jam 08:00 pagi."
    echo "   Laporan akan muncul di folder: $DIR/reports/"
fi
