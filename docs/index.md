---
layout: default
title: Home
nav_order: 1
description: "Embedded Linux Portfolio"
permalink: /
---

# PocketBeagle Embedded Linux Mastery 🐧⚙️

A structured, zero-to-hero repository documenting the transition from bare-metal firmware development and RTOS environments to full-stack Embedded Linux engineering. 

This project uses the **PocketBeagle (TI AM3358 Cortex-A8)** as the target hardware to explore everything from user-space shell scripting to custom BSP generation, Device Tree manipulation, kernel-space driver architecture and learning distributed systems interface.

---

## 📖 Repository Structure & Documentation

The documentation for this repository is hosted via GitHub Pages, built using Angular (`.ng` pages). The source code is divided into four distinct phases of the Embedded Linux architecture:

* **`/docs`**: Contains the markdown assets for the GitHub Pages site.
* **`/phase-1-user-space`**: Scripts and C applications interacting with the Linux Virtual File System (VFS).
* **`/phase-2-bsp`**: Bootloader configurations (U-Boot) and custom minimal OS generation (Buildroot).
* **`/phase-3-device-tree`**: Decompiled Device Tree Blobs (DTB) and custom pinmux routing overlays.
* **`/phase-4-kernel-space`**: Loadable Kernel Modules (LKMs), character drivers, and hardware interrupt handlers.
* **`/phase-5-distributed-systems`**: UART, I2C, MQTT, TCP/UDP.

---

## 🗺️ The Master Plan

### Phase 1: The User-Space Environment
Learning to survive as a "tenant" in the Linux ecosystem using a standard Debian image.
* **Module 1:** Command Line & The Filesystem (Boot-up bash scripting and system logging)
* **Module 2:** Sysfs & Hardware Interaction (Toggling LEDs and reading GPIO via terminal)
* **Module 3:** Cross-Compilation Toolchain (Compiling Host-to-Target C applications)

### Phase 2: Board Support Package (Building the OS)
Moving beyond pre-built images to construct a custom, ultra-minimal operating system.
* **Module 4:** U-Boot & Bootloader Sequence (UART interruption and bootargs modification)
* **Module 5:** Custom OS Generation with Buildroot (Sub-5-second boot times)

### Phase 3: Hardware as Data (The Device Tree)
Separating hardware configuration from driver code—a critical departure from traditional bare-metal MCU development.
* **Module 6:** Device Tree Syntax (Decompiling and modifying `.dtb` files)
* **Module 7:** Pin Multiplexing (Writing custom `.dts` overlays for hardware PWM routing)

### Phase 4: Kernel Space (The Device Driver Architect)
Crossing the boundary into kernel space to write code that interacts directly with hardware registers and memory management units.
* **Module 8:** The Loadable Kernel Module (LKM `hello_world.ko`)
* **Module 9:** Character Device Drivers & Virtual Memory (`ioremap()` physical to virtual mapping)
* **Module 10:** Kernel Interrupts & User-Space Handoff (The Capstone: physical button IRQs triggering user-space applications)

### Phase 5: PROJECTS ON - Distributed Systems & Connectivity
This phase focuses on how PocketBeagle talks to the outside world and other specialized hardware.
#### Module 11: The Serial Gateway (PocketBeagle <-> NodeMCU)
- **Concepts:** Asynchronous serial communication, baud rates, and parity. Using the ESP8266 as a "Wi-Fi Co-processor.
- **The Project:** The NodeMCU connects to home Wi-Fi and fetches the current temperature. It sends this data via UART to the PocketBeagle.
- **Linux Side:** We will use minicom or a C application to read /dev/ttySx and display the live rate on the PocketBeagle terminal.

#### Module 12: I2C Multi-Master/Slave (PocketBeagle <-> Pi Zero W)
- **Concepts:** The I2C bus protocol, addressing, and clock stretching. Understanding the i2c-tools utility in Linux (i2cdetect, i2cget, i2cset).
- **The Project:** Configure the PocketBeagle as an I2C Master and the Pi Zero W as an I2C Slave. The PocketBeagle "polls" the Pi Zero for its system load or CPU temperature.
* **Hardware Side:** Physical wiring of SDA/SCL lines with appropriate pull-up resistors (though the Pi usually has them built-in).

#### Module 13: Industrial Messaging with MQTT
- **Concepts:** The Publish/Subscribe model. Installing an MQTT Broker (Mosquitto) on Linux. Lightweight messaging for IoT.
- **The Project:** Run a Mosquitto broker on the Pi Zero W. Have the NodeMCU publish "Button Pressed" messages to a topic. The PocketBeagle "subscribes" to that topic and toggles a physical LED whenever a message arrives.
- **Linux Side:** Learning to use libmosquitto in C to write a subscriber client.

#### Module 14: Network Sockets (TCP/UDP) in C
- **Concepts:** The Berkeley Sockets API. Difference between connection-oriented (TCP) and connectionless (UDP) traffic in a Linux environment.
- **The Project:** Write a "Heartbeat" server in C on the PocketBeagle. The Pi Zero W acts as a client that sends a "Ping" every 5 seconds. If the PocketBeagle doesn't receive a ping, it logs a "Network Link Down" error to a file.

---

## 🛠️ Hardware & Tools
* **Target Board:** PocketBeagle (TI AM335x), raspberrypi Zero W, NodeMCU V3
* **Host OS:** WSL2 / Native Linux Desktop
* **Primary Languages:** C, Bash, Device Tree Source (DTS)
* **Core Tooling:** GCC Cross-Compiler, GNU Make, Buildroot, U-Boot

---