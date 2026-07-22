#!/bin/bash
#
# ============================================================
#  AUTOMATED SETUP - Linux System Health Check
# ------------------------------------------------------------
#  This script schedules "health_check.sh" to run
#  AUTOMATICALLY every day at 08:00 AM, so you don't need
#  to run it manually every day.
#
#  How to use:
#      bash setup_otomatis.sh
# ============================================================

# Automatically find the location of this project folder
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/health_check.sh"
LOG="$DIR/reports/automation_log.txt"

if [ ! -f "$SCRIPT" ]; then
    echo "❌ health_check.sh not found in this folder."
    exit 1
fi

# The line to be scheduled (every day at 08:00 AM)
CRON_LINE="0 8 * * * cd $DIR && bash $SCRIPT >> $LOG 2>&1"

# Check if this line already exists, to avoid duplicates
if crontab -l 2>/dev/null | grep -qF "$SCRIPT"; then
    echo "ℹ️  Automated scheduling already exists. No changes made."
else
    ( crontab -l 2>/dev/null; echo "$CRON_LINE" ) | crontab -
    echo "✅ Success! From now on, the check will run automatically"
    echo "   every day at 08:00 AM."
    echo "   Reports will appear in: $DIR/reports/"
fi
