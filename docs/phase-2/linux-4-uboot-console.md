---
layout: default
title: "Module 4. U-Boot & The Hardware Intercept"
parent: "Phase 2 : Understanding BSP"
nav_order: 1
has_children: false
---

# Module 04: U-Boot & The Hardware Intercept

## 🎯 Objectives
* Establish a physical debug connection via UART0 to monitor the pre-OS environment.
* Intercept the AM335x boot sequence to enter the U-Boot shell.
* Perform low-level hardware validation (GPIO, I2C, and Memory) using U-Boot commands.
* Analyze the environment variables that dictate how the Linux Kernel is loaded.

---

## 🛠️ Physical Setup: The Serial Console
Since SSH requires a running Linux network stack, we use a **USB-to-TTL Serial Converter** to "talk" to the board before the OS starts.

### 1. Pin Connections (PocketBeagle UART0)
The AM335x SoC uses **3.3V logic levels**. Only three wires are required for communication. 

| USB-to-Serial Cable Pin | PocketBeagle Pin | Purpose |
| :--- | :--- | :--- |
| **GND** (Ground) | **P1.22** (GND) | Common Reference |
| **RX** (Receive) | **P1.30** (UART0_TX) | Data from Board to PC |
| **TX** (Transmit) | **P1.32** (UART0_RX) | Data from PC to Board |

> **⚠️ Warning:** Do not connect the VCC (5V or 3.3V) pins from the serial cable to the board if the board is already powered via its own USB port. Ensure the cable's jumper is set to **3.3V**.



### 2. Terminal Configuration
We used **PuTTY** (or a similar terminal) with the following settings:
* **Baudrate**: 115200
* **Data bits**: 8 / **Stop bits**: 1 / **Parity**: None
* **Flow Control**: **None** (Software Flow Control must be disabled to allow keyboard input).

---

## 📜 The Intercept Procedure
1. Open the serial terminal on the Host PC, set baudrate to 115200 and partiy to 'None.
2. Keep holding **space** in Putty and apply power to the PocketBeagle.
3. **The Intercept**: As soon it powers up and space is pressed, it is in u-boot mode.
4. **Result**: The "Autoboot" process is aborted, and the board drops into the U-Boot shell:
   ```text
   Press SPACE to abort autoboot in 0 seconds
   =>
   ```
## 🔍 Hardware Validation Experiments
Once at the => prompt, we performed the following low-level hardware tests:
**1. Environment and Board Info**

*printenv:* Displayed all configuration variables (bootargs, bootcmd, etc.).

*bdinfo:* Displayed board details, including DRAM size (512 MiB) and CPU info (AM335X-GP rev 2.1).

**2. GPIO Control (LEDs)**
We bypassed the OS to manually toggle the onboard LEDs:

*gpio set 53:* Turned ON USR0 LED.

*gpio clear 53:* Turned OFF USR0 LED.

*gpio set 54:* Turned ON USR1 LED.

**3. I2C Bus Scanning**
*i2c dev 0:* Switched to the primary system I2C bus.

*i2c probe:* Identified devices at `0x24` (PMIC) and `0x50` (EEPROM).

*i2c md 0x50 0.2 20:* Read the board's serial number directly from the EEPROM.

**4. Memory and Storage**
*mmc list:* Confirmed the SD card is detected as OMAP SD/MMC: 0.

*ls mmc 0:1:* Listed files on the boot partition (e.g., sysconf.txt, ID.txt).

*md 0x82000000 20:* Inspected the kernel load address in RAM

## 🧠 Key Insights

**The "Relay Race":** Witnessed the transition from SPL (Secondary Program Loader) to U-Boot.


**Boot Arguments:** Identified that the console variable is set to ttyS0,115200n8, which is why we can see logs on UART0.


**Hush Scripting:** Analyzed the complex boot variables that automate finding the kernel and device tree across different partitions.

## 📄 Evidences**
Here are logs from putty we captured and saved as text files
[log location](../../phase-2-bsp/04-uboot/)