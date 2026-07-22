# 🖥️ Linux System Health Check

A simple script that **automatically checks the health of a Linux computer/server**, then generates a report as a web page (HTML) that's **easy for anyone to read** — including people with no Linux knowledge at all (e.g. HR, managers, or non-technical staff).

The report shows status using simple colors and emojis:

| Status | Meaning |
|--------|------|
| ✅ Healthy | Everything is normal, no action needed |
| ⚠️ Needs Attention | Should start being monitored |
| ❌ Problem | Needs action from the IT team |

---

## 📋 What Gets Checked?

1. **Processor Usage (CPU)** — whether the computer is under heavy load
2. **Memory Usage (RAM)** — whether memory is nearly full
3. **Storage Usage (Disk)** — whether the hard disk is nearly full
4. **System Uptime** — how long since the last restart
5. **Failed Login Attempts** — a simple indicator of unauthorized access attempts

---

## 🚀 How to Use

### 1. Download / Clone this project
```bash
git clone https://github.com/andriyank/Automation.git
cd Automation/linux-health-check
```

### 2. Run it once
```bash
bash health_check.sh
```

The report will be automatically created inside the `reports/` folder, named after the current date and time. Example: `reports/laporan_2026-07-22_07-36-24.html`

### 3. Open the report
Just **double-click the `.html` file** inside the `reports/` folder — it will open in your browser (Chrome/Firefox) like a normal web page. No terminal or commands needed to read it.

---

## ⏰ Run Automatically Every Day (Optional)

If you want the report to be generated automatically every day without typing anything manually, run:

```bash
bash setup_otomatis.sh
```

This will schedule `health_check.sh` to run by itself every day at 08:00 AM.

---

## 📁 Folder Structure

```
linux-health-check/
├── health_check.sh      # Main health check script
├── setup_otomatis.sh    # Schedules the daily automatic check
├── reports/              # Where all HTML reports are stored
└── README.md             # This file
```

---

## ❓ FAQ

**Does this script modify or damage the system?**
No. This script only *reads* the system's condition (CPU, RAM, disk, etc.), it doesn't change any settings.

**Does it need an internet connection?**
No, all checks are performed locally on the computer/server itself.

**Is it safe to run repeatedly?**
Yes, every run only creates a new report file — it never overwrites previous reports.

---

## 🛠️ Built For

A Kali Linux lab — as an example of simple automation whose results can still be read and understood by non-technical people like HR or management.
