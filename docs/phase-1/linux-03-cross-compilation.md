---
layout: default
title: "Module 3. The Cross-Compilation Toolchain"
parent: "Phase 1 : Understanding User space"
nav_order: 3
has_children: false
---

# Module 03: The Cross-Compilation Toolchain

## 🎯 Objectives
* Set up a Cross-Compiler (x86_64 → ARM Cortex-A8) on a Host PC.
* Resolve performance bottlenecks of shell scripting using compiled C code.
* Automate the Build-and-Deploy workflow using a `Makefile`.

---
### Set up a Cross-Compiler
Install the Toolchain (On your PC/WSL2)
```bash
sudo apt update
sudo apt install gcc-arm-linux-gnueabihf build-essential
```
whereas,
*gcc-arm-linux-gnueabihf*: This is the "Magic" compiler.

*arm*: Target architecture.

*linux*: Target OS.

*gnueabihf*: Uses the GNU C library and Hardware Floating Point (HF).


## 🛠️ The Performance Shift: Why C?
In Module 2, we observed that Bash-based LED toggling hit a "speed wall" due to the overhead of forking processes (`echo`/`tee`) and repeated file I/O. 

**C Improvements:**
* **Native Machine Code:** Instructions run directly on the ARM CPU without a shell interpreter.
* **Persistent File Descriptors:** We `open()` the sysfs file once and `write()` repeatedly, eliminating open/close overhead.
* **Microsecond Precision:** Using `nanosleep()` allows for high-frequency toggling that creates a smooth "rolling" visual effect.

---

## 📜 The Project: High-Speed Back and Forth rolling LEDs
We developed a [C application](../../phase-1-user-space/03-cross-compilation/blink.c) and a [Makefile](../../phase-1-user-space/03-cross-compilation/Makefile) to automate our workflow.

### Compilation Command (Manual):
```bash
arm-linux-gnueabihf-gcc blink.c -o blink_led_arm