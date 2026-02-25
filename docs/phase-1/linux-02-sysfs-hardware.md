---
layout: default
title: "Module 2. Everything is a File (Sysfs and usr LED Interaction)"
parent: "Phase 1 : Understanding User space"
nav_order: 2
has_children: false
---

# Module 02: "Everything is a File" (Sysfs and usr LED Interaction)

## 🎯 Objectives
* Understand the `sysfs` class-based hardware abstraction.
* Manually override kernel "Triggers" for onboard peripherals.
* Analyze the performance limits of shell-scripted hardware control.

---

## 🛠️ The LED Interface
On the PocketBeagle, the four onboard user LEDs are managed by the Linux LED Class Driver. They are exposed at:
`/sys/class/leds/beaglebone:green:usr[0-3]/`

### Anatomy of an LED Entry:
* **`brightness`**: Write `1` to turn ON, `0` to turn OFF.
* **`trigger`**: Defines the "owner" of the LED. Common triggers include `heartbeat`, `mmc0` (disk activity), or `none` (manual control).

---

## 📜 The Project: Rolling LED animation
We created a Bash script to override the default heartbeat and create a sequential "rolling" animation across the four LEDs.

### Implementation Logic (But not implemented, why? see Key Insights):
1. **Disable Triggers**: Set each LED's trigger to `none`.
2. **Infinite Loop**: Iterate through an array of LED paths.
3. **Toggle**: Write to the `brightness` file and pause using `sleep`.
4. **Non-implemented script below**
```bash
#!/bin/bash

# Array of the onboard LED paths
LEDS=(
    "/sys/class/leds/beaglebone:green:usr0"
    "/sys/class/leds/beaglebone:green:usr1"
    "/sys/class/leds/beaglebone:green:usr2"
    "/sys/class/leds/beaglebone:green:usr3"
)

# Step 1: Take manual control (Disable Heartbeat/MMC triggers)
echo "Taking control of LEDs..."
for LED in "${LEDS[@]}"; do
    echo none | sudo tee "$LED/trigger" > /dev/null
done

# Step 2: The Animation Loop
echo "Starting Knight Rider pattern... (Press Ctrl+C to stop)"
trap 'echo "Restoring defaults..."; exit' SIGINT

while true; do
    # Forward pass
    for i in {0..3}; do
        echo 1 | sudo tee "${LEDS[$i]}/brightness" > /dev/null
        sleep 0.1
        echo 0 | sudo tee "${LEDS[$i]}/brightness" > /dev/null
    done
    
    # Backward pass
    for i in {2..1}; do
        echo 1 | sudo tee "${LEDS[$i]}/brightness" > /dev/null
        sleep 0.1
        echo 0 | sudo tee "${LEDS[$i]}/brightness" > /dev/null
    done
done
```


### ⚠️ The Performance Discovery
During testing, we found that reducing `sleep` below **0.01s** or removing it entirely did **not** result in a high-speed blur. 

**Root Cause:**
* **Process Overhead:** Using `echo` and `tee` inside a Bash loop requires the OS to fork/exec new processes and handle file open/close operations repeatedly.
* **Non-Determinism:** The Linux scheduler adds jitter, making high-speed Bash-based bit-banging impossible for precision tasks.

---

## 🧠 Key Insights
* **Trigger Management:** Hardware in Linux is often "owned" by a kernel subsystem. You must release that ownership (set trigger to `none`) before manual control is possible.
* **User-Space Latency:** Bash is an orchestration tool, not a real-time control language. For high-speed hardware interaction, we must move to compiled C code.

### Revised Implementation Logic
1. **file descriptor**: we can open a "File Descriptor" and keep it open. This removes the overhead of opening the file repeatedly.
2. **Infinite Loop**: Iterate through opened file descriptor.
3. **Toggle**: Write to the `brightness` file and pause using `sleep`.
4. **Implemented script [roll_led.sh](../../phase-1-user-space/02-sysfs-hardware/roll_led.sh**

---