#!/bin/bash
#
# ============================================================
#  LINUX SYSTEM HEALTH CHECK
# ------------------------------------------------------------
#  This script automatically checks the health of your Linux
#  computer/server, then generates a report in HTML format
#  that's easy for anyone to read (no Linux knowledge needed).
#
#  How to use:
#      bash health_check.sh
#
#  The report will be saved inside the "reports/" folder,
#  named after the current date and time.
# ============================================================

# --- Prepare the reports folder ---
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"

DATE_STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DATE_DISPLAY=$(date +"%d %B %Y, %H:%M")
REPORT_FILE="$REPORT_DIR/report_$DATE_STAMP.html"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Determines status based on usage percentage
# < 70%  = Healthy (green)
# 70-90% = Needs Attention (yellow)
# > 90%  = Problem (red)
determine_status() {
    local percent=$1
    if (( percent < 70 )); then
        echo "HEALTHY"
    elif (( percent < 90 )); then
        echo "ATTENTION"
    else
        echo "PROBLEM"
    fi
}

status_color() {
    case "$1" in
        HEALTHY) echo "#2ecc71" ;;   # green
        ATTENTION) echo "#f1c40f" ;; # yellow
        PROBLEM) echo "#e74c3c" ;;   # red
    esac
}

status_label() {
    case "$1" in
        HEALTHY) echo "✅ Healthy" ;;
        ATTENTION) echo "⚠️ Needs Attention" ;;
        PROBLEM) echo "❌ Problem" ;;
    esac
}

# ============================================================
# 1. CHECK CPU USAGE
# ============================================================
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | grep -o '[0-9.]*')
CPU_USAGE=$(printf "%.0f" "$(echo "100 - $CPU_IDLE" | bc 2>/dev/null || echo 0)")
[ -z "$CPU_USAGE" ] && CPU_USAGE=0
STATUS_CPU=$(determine_status "$CPU_USAGE")

# ============================================================
# 2. CHECK RAM (MEMORY) USAGE
# ============================================================
RAM_INFO=$(free -m | awk '/Mem:/ {printf "%d %d %.0f", $3, $2, ($3/$2)*100}')
RAM_USED=$(echo "$RAM_INFO" | awk '{print $1}')
RAM_TOTAL=$(echo "$RAM_INFO" | awk '{print $2}')
RAM_PERCENT=$(echo "$RAM_INFO" | awk '{print $3}')
STATUS_RAM=$(determine_status "$RAM_PERCENT")

# ============================================================
# 3. CHECK DISK (STORAGE) USAGE
# ============================================================
DISK_INFO=$(df -h / | awk 'NR==2 {print $3, $2, $5}' | tr -d '%')
DISK_USED=$(echo "$DISK_INFO" | awk '{print $1}')
DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $3}')
STATUS_DISK=$(determine_status "$DISK_PERCENT")

# ============================================================
# 4. CHECK SYSTEM UPTIME
# ============================================================
UPTIME_TEXT=$(uptime -p 2>/dev/null | sed 's/up //')
[ -z "$UPTIME_TEXT" ] && UPTIME_TEXT=$(uptime)

# ============================================================
# 5. CHECK FAILED LOGIN ATTEMPTS (simple security indicator)
# ============================================================
if [ -f /var/log/auth.log ]; then
    FAILED_LOGINS=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null)
else
    FAILED_LOGINS="Cannot be checked (log not found)"
fi

if [[ "$FAILED_LOGINS" =~ ^[0-9]+$ ]]; then
    if (( FAILED_LOGINS == 0 )); then
        STATUS_LOGIN="HEALTHY"
    elif (( FAILED_LOGINS < 20 )); then
        STATUS_LOGIN="ATTENTION"
    else
        STATUS_LOGIN="PROBLEM"
    fi
else
    STATUS_LOGIN="ATTENTION"
fi

# ============================================================
# OVERALL SUMMARY (worst status determines the final verdict)
# ============================================================
SUMMARY="HEALTHY"
for s in "$STATUS_CPU" "$STATUS_RAM" "$STATUS_DISK" "$STATUS_LOGIN"; do
    if [ "$s" == "PROBLEM" ]; then
        SUMMARY="PROBLEM"
        break
    elif [ "$s" == "ATTENTION" ] && [ "$SUMMARY" != "PROBLEM" ]; then
        SUMMARY="ATTENTION"
    fi
done

# ============================================================
# GENERATE HTML REPORT
# ============================================================
cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>System Health Report - $DATE_DISPLAY</title>
<style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background:#f4f6f8; margin:0; padding:0; color:#2c3e50; }
    .container { max-width: 750px; margin: 30px auto; background:#fff; border-radius:10px; box-shadow:0 2px 10px rgba(0,0,0,0.08); overflow:hidden; }
    .header { background:$(status_color "$SUMMARY"); color:#fff; padding:25px 30px; }
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
        <h1>System Health Report</h1>
        <p>Generated on: $DATE_DISPLAY</p>
        <p>Overall Status: $(status_label "$SUMMARY")</p>
    </div>
    <div class="content">
        <table>
            <tr><th>Component</th><th>Details</th><th>Status</th></tr>
            <tr>
                <td>Processor Usage (CPU)</td>
                <td>${CPU_USAGE}% used</td>
                <td><span class="badge" style="background:$(status_color "$STATUS_CPU")">$(status_label "$STATUS_CPU")</span></td>
            </tr>
            <tr>
                <td>Memory Usage (RAM)</td>
                <td>${RAM_USED} MB of ${RAM_TOTAL} MB (${RAM_PERCENT}%)</td>
                <td><span class="badge" style="background:$(status_color "$STATUS_RAM")">$(status_label "$STATUS_RAM")</span></td>
            </tr>
            <tr>
                <td>Storage Usage (Disk)</td>
                <td>${DISK_USED} of ${DISK_TOTAL} (${DISK_PERCENT}%)</td>
                <td><span class="badge" style="background:$(status_color "$STATUS_DISK")">$(status_label "$STATUS_DISK")</span></td>
            </tr>
            <tr>
                <td>System Uptime</td>
                <td>$UPTIME_TEXT</td>
                <td>—</td>
            </tr>
            <tr>
                <td>Failed Login Attempts</td>
                <td>$FAILED_LOGINS</td>
                <td><span class="badge" style="background:$(status_color "$STATUS_LOGIN")">$(status_label "$STATUS_LOGIN")</span></td>
            </tr>
        </table>

        <div class="notes">
            <b>Legend:</b><br>
            ✅ <b>Healthy</b> = Everything is normal, no action needed.<br>
            ⚠️ <b>Needs Attention</b> = Should start being monitored, not urgent yet.<br>
            ❌ <b>Problem</b> = Action needed / contact IT team as soon as possible.
        </div>
    </div>
    <div class="footer">
        Report generated automatically by Linux System Health Check &mdash; no manual action required.
    </div>
</div>
</body>
</html>
EOF

echo ""
echo "=========================================="
echo " Check complete!"
echo " Overall system status: $SUMMARY"
echo " Report saved to: $REPORT_FILE"
echo "=========================================="
echo ""
