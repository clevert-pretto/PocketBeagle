---
layout: default
title: "Phase 2 : Understanding BSP"
nav_order: 3
has_children: true
---


## 🏃 The 4-Stage Relay Race - PocketBeagle boot process

For the TI AM335x (PocketBeagle), the boot process is a 4-stage relay race.

**1. Stage 1: ROM Code (The "Hard-Wired" Logic)**
The moment you apply power, the CPU is "dumb." It only knows how to execute a tiny piece of code burned into its silicon at the factory (the ROM Code).

**What it does:** It checks the "Boot Pins" (on the PocketBeagle, these are hard-wired to look at the SD card first).

**The Hand-off:** It looks for a file named MLO (Memory Location Optimizer) on the FAT partition and copies it into the tiny Internal SRAM (about 128KB) because the main DDR3 RAM isn't "awake" yet.

**2. Stage 2: SPL (Secondary Program Loader)**
The MLO file is actually the U-Boot SPL.

**What it does:** Its #1 job is to initialize the DDR3 RAM. Without this, you can't load the massive Linux kernel. It also sets up the "Muxing" for the basic pins.

**The Hand-off:** Once RAM is alive, it finds the much larger u-boot.img file on the SD card, copies it into the now-active DDR3 RAM, and jumps to it.

**3. Stage 3: U-Boot (The "Full" Bootloader)**
This is the `=>` prompt you saw earlier. This is a mini-operating system.

**What it does:** It provides the command-line interface, handles the network (if enabled), and most importantly, it loads the Kernel (`zImage`) and the Device Tree (`.dtb`) from the SD card into specific memory addresses in RAM.

**The Hand-off:** It executes the bootz command. This is the "Point of No Return." U-Boot clears itself from memory and hands total control to the Linux Kernel.

**4. Stage 4: Linux Kernel & Init**
The Kernel takes over, reads the Device Tree to find the hardware, and eventually mounts the Root Filesystem (`rootfs`).

**What it does:** It starts the very first user-space process: init (or`Systemd/BusyBox sbin/init`).

**The Finish Line:** init starts the serial console service, and you see login prompt.