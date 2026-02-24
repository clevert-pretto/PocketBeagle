---
layout: default
title: "Phase 1 : Module 1 The command line and Filesystem"
parent: "Phase 1 : Understanding User space"
nav_order: 2
has_children: false
---

# Module 01: The Command Line & The Filesystem

## 🎯 Objectives
* Navigate the Linux filesystem hierarchy using standard CLI tools.
* Understand the `sysfs` virtual filesystem and how Linux exposes hardware metrics.
* Automate system monitoring using Bash scripting.
* Configure a script to execute automatically on system boot.

---

## 🛠️ The Hardware Interface
In Embedded Linux, the kernel manages the SoC's thermal sensors and exposes the data via the **Virtual File System (VFS)**. For the PocketBeagle (AM335x), the CPU temperature is found here:
` /sys/class/thermal/thermal_zone0/temp`

### Manual Verification
Before scripting, we can read the raw temperature (in millidegrees Celsius) directly from the terminal:
```bash
cat /sys/class/thermal/thermal_zone0/temp
```

### The Project: Boot Temperature Logger
We created a Bash script to capture the CPU temperature during the boot sequence and log it to a persistent text file.

Source Code: `temp_logger.sh`