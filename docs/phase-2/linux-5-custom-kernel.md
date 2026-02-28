---
title: "Module 05: Building and Deploying a Custom Linux Kernel for PocketBeagle"
parent: "Phase 2 : Understanding BSP"
nav_order: 2
---

# Module 05: Building and Deploying a Custom Linux Kernel for PocketBeagle

This guide details the process of compiling a custom Linux kernel on a host machine (WSL2 Debian/Ubuntu) and deploying it to a TI AM335x-based PocketBeagle, including resolving common U-Boot console and partition routing issues.

---

## 🛠️ Phase 1: Host Environment Setup (WSL2)

Before compiling the kernel, the host machine requires specific utilities to handle C compilation, cryptographic signing, archiving, and BPF Type Format (BTF) generation.

Run the following command to install all necessary dependencies:

```bash
sudo apt update
sudo apt install flex bison build-essential libncurses-dev libssl-dev bc lzop rsync cpio pahole kmod util-linux
```

## ⚙️ Phase 2: Kernel Configuration and Compilation
1. Git clone the right repository and branch

```bash
git clone --depth 1 -b v6.12.34-ti-arm32-r12 https://github.com/beagleboard/linux.git
cd linux
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bb.org_defconfig
```

2. Set Build Variables

Define the architecture and the cross-compiler prefix to ensure the kernel is built for the 32-bit ARM processor rather than the host PC.

```Bash
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
```

3. Customize the Kernel
Open the visual configuration menu to append a custom local version string.

```Bash
make menuconfig
```

- Navigate to **General setup -> Local version - append to kernel release**.
- Enter your custom tag (e.g., -ravi-custom-v1).
- Save and exit.

4. Compile the Kernel, Modules, and Device Tree
Execute the build utilizing all available CPU cores.

```Bash
make -j$(nproc) zImage modules dtbs
```
Expected Output on Success:

```Plaintext
  OBJCOPY arch/arm/boot/zImage
  Kernel: arch/arm/boot/zImage is ready
```

5. Module Packaging
Kernel modules (.ko files) must be installed into a temporary directory on the host, compressed into an archive, and then extracted on the board.

- Install to Temporary Directory
```Bash
mkdir -p $HOME/temp_modules
make INSTALL_MOD_PATH=$HOME/temp_modules modules_install
```
- Compress the Modules
```Bash
cd $HOME/temp_modules
tar -cvzf modules.tar.gz lib/modules/
```

## 🚀 Phase 3: File Transfer
Transfer the compressed modules, compiled compressed kernel (zImage) and the compiled hardware map (Device Tree Blob / .dtb) to the live PocketBeagle over SSH.

Run on Host PC:

```Bash
# Transfer Kernel
scp arch/arm/boot/zImage debian@192.168.7.2:/home/debian/zImage

# Transfer compressed modules
```Bash
scp modules.tar.gz debian@192.168.7.2:/home/debian/


# Transfer Device Tree Blob
scp arch/arm/boot/dts/am335x-pocketbeagle.dtb debian@192.168.7.2:/home/debian/am335x-pocketbeagle-custom.dtb
```

Run on PocketBeagle:
Move the transferred files into the system's /boot directory.

```Bash
# Move zImage in /boot directory
sudo mv /home/debian/zImage /boot/zImage

# Move dtb in /boot/dtbs directory
sudo mv /home/debian/am335x-pocketbeagle-custom.dtb /boot/dtbs/am335x-pocketbeagle

# Extract modules
sudo tar -xvzf /home/debian/modules.tar.gz -C /
```

## 🧪 Phase 4: Manual U-Boot Boot Test
To avoid bricking the board, we perform a manual boot to verify the configuration.

1. Interrupt Boot: Tap Space in the serial console during power-on to reach the => prompt.

2. Verify Partitions:

```Bash
mmc part
```
*(Partition 3 is typically the root filesystem on modern images).*

3. Set Console Path (Crucial Fix):

```Bash
setenv bootargs console=ttyO0,115200n8 root=/dev/mmcblk0p3 ro rootfstype=ext4 rootwait earlycon
```
4. Set Boot Arguments (The Console Fix)
Crucial step: The AM335x UART0 requires the specific OMAP serial driver (ttyO0). If left as ttyS0, the board will boot but the console will hang at "Starting kernel...".

```Bash
=> setenv bootargs console=ttyO0,115200n8 root=/dev/mmcblk0p3 ro rootfstype=ext4 rootwai
```

5. Load and Boot:

```Bash
load mmc 0:3 ${loadaddr} /boot/zImage
load mmc 0:3 ${fdtaddr} /boot/dtbs/am335x-pocketbeagle-custom.dtb
bootz ${loadaddr} - ${fdtaddr}
```

## 🏆 Phase 5: Verification
Once the boot logs finish scrolling and the login prompt appears, log in and verify the kernel version.

```Bash
uname -a
Expected Output:
Linux version 6.1.x-ravi-custom-v1 ...
```

## 💾 Phase 6: Making the Custom Kernel Permanent

To ensure the PocketBeagle boots your custom kernel automatically every time it powers on, you must update the `uEnv.txt` file. This file contains the environment variables that U-Boot reads during the boot sequence.

### 1. Identify your Boot Configuration
Most BeagleBoard-style images use one of two methods in `uEnv.txt`. SSH into the board and open the file:

```bash
sudo nano /boot/uEnv.txt
```
### 2. Method A: The uname_r Method (Recommended)
If your `uEnv.txt` has a line starting with `uname_r=`, the boot scripts are designed to look for kernels in `/boot/vmlinuz-${uname_r}`.

- Rename your kernel to match this pattern:

```Bash
sudo mv /boot/zImage /boot/vmlinuz-6.1.x-ravi-custom-v1
```
Update uEnv.txt:

```Plaintext
uname_r=6.1.x-ravi-custom-v1
```
### 3. Method B: Direct Path Overrides
If you want to explicitly point to your specific filenames regardless of the version string, add or modify these lines in uEnv.txt:

```Plaintext
# Manually specify the kernel and DTB
image=zImage
fdtfile=dtbs/am335x-pocketbeagle-custom.dtb

# Ensure the console argument matches the one used in our manual test
cmdline=console=ttyO0,115200n8 root=/dev/mmcblk0p3 ro rootfstype=ext4 rootwait earlycon
```

## ⚠️ Recovery Procedure (Safety Net)
If the board fails to boot after these changes, you can still recover without reflashing the SD card:

1. Remove the SD card and plug it into your Host PC.

2. The "Boot" partition (usually Partition 1) should be visible.

3. Open uEnv.txt on your PC and revert the changes or point uname_r back to the original working version.

4. Re-insert the card into the PocketBeagle and boot again.

## 🏁 Final Verification
After saving uEnv.txt and rebooting (sudo reboot), wait for the board to come back online. Log in and run:

```Bash
uname -a
```
If you see your custom tag without having to type any U-Boot commands, your deployment is complete and permanent.

---