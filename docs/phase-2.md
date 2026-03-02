---
layout: default
title: "Phase 2 : Understanding BSP"
nav_order: 3
has_children: true
---

# Pocket Beagle Power up log analysis from serial termianl

[The log file](../phase-1-user-space/POWER_UP_LOGS_for_am335x-debian-13.3-base-v6.18-armhf-2026-01-22-4gb.img.txt)

To understand boot process steps theroetically, refer [The 4-Stage Relay Race - PocketBeagle boot process](./phase-1.md)

**Target Device:** BeagleBoard.org PocketBeagle (AM335x)
**Image:** Debian 13.3 Base (Kernel 6.18.6-bone16)

## Phase 1: Bootloader (U-Boot)

1. The boot process begins with the **hardware ROM** executing the U-Boot Secondary Program Loader (SPL). Because the PocketBeagle lacks onboard eMMC, the SPL targets MMC1 (the MicroSD card slot).

2. U-Boot initializes fundamental hardware components, detecting 512 MiB of DRAM. It then searches the SD card for the boot environment variables located in /boot/uEnv.txt. This file instructs U-Boot to load the **Linux Kernel** (vmlinuz-6.18.6-bone16), the **Device Tree Blob** (am335x-pocketbeagle.dtb), and the **Initial RAM Disk** (initrd.img-6.18.6-bone16) into memory before handing over execution.

## Phase 2: Kernel Initialization & Hardware Bring-Up

1. The kernel begins executing at physical CPU address 0x0, utilizing a single ARM Cortex-A8 processor running at a calibrated 995.32 BogoMIPS.

2. Memory & Resource Allocation: The kernel establishes memory zones, reserving 48 MiB specifically for the Contiguous Memory Allocator (CMA), which is vital for providing unbroken chunks of memory to hardware drivers that cannot handle scattered pages.

3. Subsystem Initialization: The core networking stack (IPv4/IPv6, Netlink), cryptography APIs (utilizing NEON acceleration), and essential hardware controllers (I2C, GPIO, DMA) are activated.

4. USB & Peripheral Subsystems: The Mentor Graphics (MUSB) host controllers detect the onboard USB configurations. Note: There is a recurring debug warning regarding a VBUS_ERROR (VBUS_ERROR in a_wait_vrise (80, <SessEnd), retry #3), indicating a slight instability or missing configuration on the USB power delivery lines during startup.

## Phase 3: User Space (systemd) & The First-Boot Cycle
1. Once the kernel has laid the groundwork, it hands control to **init** (systemd version 257.9).

2. During this initial boot, a specialized service (bbbio-set-sysconf.service) detects that the root filesystem (/dev/mmcblk0p3) has not been optimized for the size of the SD card. The service triggers resize2fs, successfully expanding the filesystem from 780,288 blocks to 3,748,219 blocks to reclaim the full 14.8 GiB of available storage.

3. Because system configurations have been altered, the system orchestrates a graceful shutdown. It flushes journals , detaches loop devices , unmounts the newly resized Ext4 partition , and triggers a global warm software reboot.

## Phase 4: Final Boot sequence
1. Upon the second boot, the initialization mirrors the first, but the resize scripts do not run. Services execute rapidly:

2. Networking & Services: The systemd-networkd service configures the interfaces , while nginx (web server) and ssh (secure shell) spin up successfully.

3. USB Gadgets: The board configures itself as a **composite USB gadget** , providing network over USB and a **serial console (ttyGS0)** to the host computer.

4. Login Prompt: The sequence concludes successfully, dropping the system into the ttyS0 serial login prompt, ready for interaction.