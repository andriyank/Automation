# 🖥️ Windows System Health Check

The **PowerShell** version of the Linux Health Check — to check the health of a **Windows laptop/PC directly** (not through WSL), so the data will **match what you see in Task Manager**.

The report is a web page (HTML) that's easy for anyone to read, including non-technical people (HR, managers, etc.), with status indicators:

| Status | Meaning |
|--------|------|
| ✅ Healthy | Everything is normal, no action needed |
| ⚠️ Needs Attention | Should start being monitored |
| ❌ Problem | Needs action from the IT team |

---

## 📋 What Gets Checked?

1. **CPU** — processor load
2. **RAM** — memory usage
3. **Disk (Drive C:)** — remaining storage space
4. **Uptime** — how long since the laptop was last restarted
5. **Failed Login Attempts** — from the Windows Security Log (needs to run as Administrator to be readable)

---

## 🚀 How to Use

Don't use Git? Download without it

No terminal or Git knowledge needed:

Go to the repo page
Click the green < > Code button → "Download ZIP"
Extract the ZIP, then open the windows-health-check folder

To download just this folder (not the whole repo), go to https://download-directory.github.io, paste this link: https://github.com/andriyank/Automation/tree/main/windows-health-check, then press Enter.

### 1. Open the `windows-health-check` folder

### 2. Right-click `health_check.ps1` → **Run with PowerShell**

> If you see an error like *"cannot be loaded because running scripts is disabled..."*, that's because Windows blocks PowerShell scripts by default (for security). To fix it:
>
> 1. Open **PowerShell as Administrator**
> 2. Run this command once:
>    ```powershell
>    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
>    ```
> 3. Type `Y` and press Enter
> 4. Try running `health_check.ps1` again

### Alternative: Run Without Changing System Settings

If you don't want to change your PowerShell execution policy, you can run the script directly with:
```powershell
powershell -ExecutionPolicy Bypass -File .\health_check.ps1
```
This temporarily allows the script to run just for this one execution, without permanently changing any settings on your system.

### 3. Result
The report will automatically **open in your browser**, and will also be saved inside the `reports\` folder.

---

## ⏰ Run Automatically Every Day (Optional)

1. Right-click `setup_otomatis.ps1` → **Run with PowerShell as Administrator**
2. Done — starting tomorrow, the report will be generated automatically every day at 08:00 AM via Windows Task Scheduler

---

## 📁 Folder Structure

```
windows-health-check/
├── health_check.ps1      # Main health check script
├── setup_otomatis.ps1    # Schedules the daily automatic check
├── reports/               # Where all HTML reports are stored
└── README.md              # This file
```

---

## ❓ When to Use This vs the Linux (WSL) Version?

| Situation | Use |
|---|---|
| Want to monitor the **whole Windows laptop/PC** (matching Task Manager) | This **Windows (PowerShell)** version |
| Want to monitor the **Kali Linux / WSL environment** only | The **Linux (Bash)** version |

Data differs between WSL and Windows because WSL is only given a separate "share" of RAM/CPU by Windows, and doesn't see the condition of the entire laptop.
