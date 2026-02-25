---
layout: default
title: "Module 1. The command line and Filesystem"
parent: "Phase 1 : Understanding User space"
nav_order: 1
has_children: false
---

# Module 01: The Command Line & The Filesystem

## 🎯 Objectives
* Navigate the Linux Filesystem Hierarchy Standard (FHS).
* Differentiate between `/sys` (Hardware/Drivers) and `/proc` (System/Processes).
* Automate background system monitoring using Bash and Crontab.

---

## 🛠️ The Hardware & OS Audit
During the initial phase, we attempted to read the internal thermal sensor of the AM335x SoC. However, a filesystem audit of the `/boot/dtbs/` directory revealed that the current kernel build (`6.18.10-bone20`) lacks the necessary Thermal Zone drivers/overlays.

### Audit Command:
```bash
find /sys -name "*temp*" 2>/dev/null
```
*Result: No hardware-mapped thermal files found.*

### The Project: System Health Logger
Since thermal data was unavailable, we pivoted to a System Health Logger to monitor Uptime and Free Memory, which are exposed via the procfs virtual filesystem.

Source Code: `health_logger.sh` placed at `/home/debian/PocketBeagle/phase-1-user-space/01-cli-scripting/`

```bash
#!/bin/bash

LOG_FILE="/home/debian/PocketBeagle/phase-1-user-space/01-cli-scripting/system_health.log"

# Extract 1st value from /proc/uptime (Seconds since boot)
UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UPTIME_SEC=${UPTIME_RAW%.*}

# Extract Free Memory from /proc/meminfo
MEM_FREE=$(grep "MemFree" /proc/meminfo | awk '{print $2 " " $3}')

# Timestamp and Append
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Uptime: ${UPTIME_SEC}s | Free RAM: $MEM_FREE" >> "$LOG_FILE"
```
