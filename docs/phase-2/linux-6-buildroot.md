---
title: "Module 06: Buildroot - Automating the process of building Linux system"
parent: "Phase 2 : Understanding BSP"
nav_order: 3
---

## What is Buildroot?
Buildroot is a tool that automates the entire process of generating a complete Linux system for an embedded device. Instead of manually compiling the toolchain, U-Boot, and the Kernel separately, Buildroot uses one single configuration file to build:

1. Cross-compilation Toolchain

2. Bootloader (U-Boot)

3. Linux Kernel

4. Root Filesystem (containing only the apps you choose)

While the kernel build gave you a custom version of Linux, you are still running it on top of a heavy, pre-built Debian filesystem. Buildroot allows you to move away from Debian and create a tiny, high-performance, and fully customized Root Filesystem (RootFS) from scratch.

## Why move to Buildroot now?
**Size:** Current Debian image is likely 1GB–4GB. A Buildroot image for the PocketBeagle can be as small as 5MB–20MB.

**Boot Time:** Because it only starts the services you define, it can boot in seconds rather than nearly a minute.

**Full Control:** You will build the busybox utilities that provide your `ls`, `cd`, and `mkdir` commands.

## 🛠️ Phase 1: Environment Setup & Dependencies
Buildroot is a "heavy" builder. It will download source code for every tool and library you select. Before we start, ensure your WSL2 system has the following extra tools needed for the Buildroot automated scripts:

```Bash
# Update package lists
sudo apt-get update

# Install essential build tools and libraries (including EFI/GnuTLS dependencies for U-Boot 2024+)
sudo apt-get install -y build-essential gcc g++ gawk wget git-core diffutils unzip texinfo \
gcc-multilib bison flex libc6-dev-i386 libncurses5-dev libssl-dev libgnutls28-dev uuid-dev
```

## Hardware and tools details
**Target Hardware:** TI AM335x PocketBeagle
**Host Environment:** Ubuntu (WSL2)
**Build System:** Buildroot
**Kernel Version:** Linux 6.12.x
**U-Boot Version:** 2024.10

## ⚙️ Phase 2: Buildroot Base Configuration
Initialize the Buildroot environment and set the target architecture for the AM335x processor.

1. Navigate to your Buildroot directory: cd ~/PocketBeagle/phase-2-bsp/06-buildroot/buildroot

2. Open the configuration menu: make menuconfig

**Target Options:**

- Target Architecture: ARM (little endian)

- Target Architecture Variant: cortex-A8

- Target ABI: EABIhf

- Floating point strategy: VFPv3-D16

**System Configuration:**

- System hostname: ravi-beagle (or your preferred name)

- Root password: Set a secure password here to enable the login prompt.

## 🐧 Phase 3: Linux Kernel Configuration
Configure Buildroot to compile the custom Linux 6.12.x kernel and the specific Device Tree for the PocketBeagle.

**Kernel Menu (`make menuconfig` -> Kernel):**

**Kernel Version:** *Custom tarball* or *Custom Git repository* (pointing to your 6.12.x source).

**Defconfig name:** *omap2plus*

**Kernel binary format:** *zImage*

**Device Tree Support:** *[*] Enable Device Tree Support*

**In-tree Device Tree Source file names:** *ti/omap/am335x-pocketbeagle*

*Note on DTS Paths*: If Buildroot throws a "No rule to make target" error for the .dtb, ensure the path correctly reflects the manufacturer subfolder (ti/omap/) introduced in newer 6.x kernels, or manually copy the .dts to the root arch/arm/boot/dts/ folder and update the config string to just `am335x-pocketbeagle`.

## 🚀 Phase 4: U-Boot & The Timer Fix
Configure the bootloader. The AM335x processor has specific hardware timer requirements that conflict with modern U-Boot's Driver Model (DM) when using generic board configs.

1. **Base U-Boot Config (`make menuconfig` -> Bootloaders):**

**U-Boot Version:** *Custom version -> 2024.10*

**Board defconfig:** *am335x_evm*

**U-Boot binary format:** *u-boot.img*

**Install U-Boot SPL:** *[*] Check this (Name: MLO)*

2. **The Legacy Timer Fix (`make uboot-menuconfig`):**
To prevent the Could not initialize timer (err -19) boot loop panic, we must disable U-Boot's modern timer framework and fall back to the legacy hardware clock.

- Navigate to *Device Drivers* ---> *Timer Support*.

- UNCHECK the master switch: *[ ] Enable timer support* (Press Space so the asterisk disappears).

- Save and Exit.

## 📦 Phase 5: Root Filesystem & Packaging
Ensure the root filesystem partition is large enough to hold modern kernel modules.

**Filesystem Images (`make menuconfig` -> `Filesystem images`):**

- **[*] ext2/3/4 root filesystem**

- **ext2/3/4 variant:** *ext4*

- **exact size:** *256M* (Increased from the default 60M to prevent mke2fs block allocation errors).

**Execute the Build:**

```Bash
make
```
If a rebuild is necessary due to configuration changes, use make `linux-dirclean`, `make uboot-dirclean`, or `make uboot-rebuild` prior to running `make`.

## ⚡ Phase 6: SD Card Flashing & Boot Automation
Once the build is complete, flash the generated image located at `output/images/sdcard.img` to your MicroSD card using a tool like balenaEtcher or Rufus.

**Automating the Boot Sequence (uEnv.txt)**
To bypass U-Boot's modern "Distro Boot" network-search loop and automatically load the custom kernel, create a file named `uEnv.txt` on the root of the FAT32 boot partition of the SD card.

Contents of `uEnv.txt`:

```Plaintext
bootfile=zImage
fdtfile=am335x-pocketbeagle.dtb
bootpartition=mmcblk0p2
console=ttyO0,115200n8
loadaddr=0x82000000
fdtaddr=0x88000000

loadimage=fatload mmc 0:1 ${loadaddr} ${bootfile}
loadfdt=fatload mmc 0:1 ${fdtaddr} ${fdtfile}
set_bootargs=setenv bootargs console=${console} root=/dev/${bootpartition} rw rootfstype=ext4 rootwait
uenvcmd=run set_bootargs; run loadimage; run loadfdt; printenv bootargs; bootz ${loadaddr} - ${fdtaddr}
```

*Note: The AM335x native UART console is ttyO0 (capital letter O, number zero).*

## The Final Result
Insert the SD card, connect the serial debug cable, and apply power. U-Boot will read `uEnv.txt`, load the kernel and device tree into RAM, and execute the boot sequence, resulting in the custom Buildroot login prompt:

```bash
U-Boot SPL 2024.10 (Feb 28 2026 - 17:36:11 +0000)
Trying to boot from MMC1


U-Boot 2024.10 (Feb 28 2026 - 17:36:11 +0000)

CPU  : AM335X-GP rev 2.1
Model: TI AM335x PocketBeagle
DRAM:  512 MiB
Core:  155 devices, 16 uclasses, devicetree: separate
WDT:   Started wdt@44e35000 with servicing every 1000ms (60s timeout)
NAND:  0 MiB
MMC:   OMAP SD/MMC: 0
Loading Environment from FAT... OK
Net:   No ethernet found.
Hit any key to stop autoboot:  0
437 bytes read in 1 ms (426.8 KiB/s)
Importing environment from mmc ...
Running uenvcmd ...
7322168 bytes read in 459 ms (15.2 MiB/s)
68669 bytes read in 7 ms (9.4 MiB/s)
bootargs=console=ttyO0,115200n8 root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait
Kernel image @ 0x82000000 [ 0x000000 - 0x6fba38 ]
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
Working FDT set to 88000000
   Loading Device Tree to 8ffec000, end 8ffffc3c ... OK
Working FDT set to 8ffec000

Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 6.12.34 (ravichilwant@RAVI-HP) (arm-buildroot-linux-gnueabihf-gcc.br_real (Buildroot 2023.02.11) 11.4.0, GNU ld (GNU Binutils) 2.38) #4 SMP Sat Feb 28 18:01:55 UTC 2026
[    0.000000] CPU: ARMv7 Processor [413fc082] revision 2 (ARMv7), cr=10c5387d
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
[    0.000000] OF: fdt: Machine model: TI AM335x PocketBeagle
[    0.000000] Memory policy: Data cache writeback
[    0.000000] cma: Reserved 16 MiB at 0x9e800000 on node -1
[    0.000000] Zone ranges:
[    0.000000]   Normal   [mem 0x0000000080000000-0x000000009fdfffff]
[    0.000000]   HighMem  empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x000000009fdfffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x000000009fdfffff]
[    0.000000] OF: reserved mem: Reserved memory: No reserved-memory node in the DT
[    0.000000] CPU: All CPU(s) started in SVC mode.
[    0.000000] AM335X ES2.1 (sgx neon)
[    0.000000] percpu: Embedded 17 pages/cpu s40652 r8192 d20788 u69632
[    0.000000] Kernel command line: console=ttyO0,115200n8 root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait
[    0.000000] Dentry cache hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.000000] Inode-cache hash table entries: 32768 (order: 5, 131072 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 130560
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU event tracing is enabled.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=2 to nr_cpu_ids=1.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] NR_IRQS: 16, nr_irqs: 16, preallocated irqs: 16
[    0.000000] IRQ: Found an INTC at 0x(ptrval) (revision 5.0) with 128 interrupts
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] TI gptimer clocksource: always-on /ocp/interconnect@44c00000/segment@200000/target-module@31000
[    0.000004] sched_clock: 32 bits at 24MHz, resolution 41ns, wraps every 89478484971ns
[    0.000029] clocksource: dmtimer: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 79635851949 ns
[    0.000475] TI gptimer clockevent: 24000000 Hz at /ocp/interconnect@48000000/segment@0/target-module@40000
[    0.001891] Console: colour dummy device 80x30
[    0.001948] WARNING: Your 'console=ttyO0' has been replaced by 'ttyS0'
[    0.001956] This ensures that you still see kernel messages. Please
[    0.001961] update your kernel commandline.
[    0.002004] Calibrating delay loop... 996.14 BogoMIPS (lpj=4980736)
[    0.090517] CPU: Testing write buffer coherency: ok
[    0.090626] CPU0: Spectre v2: using BPIALL workaround
[    0.090635] pid_max: default: 32768 minimum: 301
[    0.090756] LSM: initializing lsm=capability
[    0.090935] Mount-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.090955] Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.092530] CPU0: thread -1, cpu 0, socket -1, mpidr 0
[    0.094628] Setting up static identity map for 0x80100000 - 0x80100078
[    0.094947] rcu: Hierarchical SRCU implementation.
[    0.094958] rcu:     Max phase no-delay instances is 1000.
[    0.096101] smp: Bringing up secondary CPUs ...
[    0.096147] smp: Brought up 1 node, 1 CPU
[    0.096159] SMP: Total of 1 processors activated (996.14 BogoMIPS).
[    0.096170] CPU: All CPU(s) started in SVC mode.
[    0.096331] Memory: 482016K/522240K available (11264K kernel code, 1159K rwdata, 2740K rodata, 1024K init, 296K bss, 22212K reserved, 16384K cma-reserved, 0K highmem)
[    0.097113] devtmpfs: initialized
[    0.111876] VFP support v0.3: implementor 41 architecture 3 part 30 variant c rev 3
[    0.112207] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.112240] futex hash table entries: 256 (order: 2, 16384 bytes, linear)
[    0.113561] pinctrl core: initialized pinctrl subsystem
[    0.115659] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.118502] DMA: preallocated 256 KiB pool for atomic coherent allocations
[    0.119061] audit: initializing netlink subsys (disabled)
[    0.120379] thermal_sys: Registered thermal governor 'fair_share'
[    0.120393] thermal_sys: Registered thermal governor 'step_wise'
[    0.120404] thermal_sys: Registered thermal governor 'user_space'
[    0.120796] audit: type=2000 audit(0.000:1): state=initialized audit_enabled=0 res=1
[    0.120840] cpuidle: using governor menu
[    0.138662] No ATAGs?
[    0.138686] hw-breakpoint: debug architecture 0x4 unsupported.
[    0.141425] kprobes: kprobe jump-optimization is enabled. All kprobes are optimized if possible.
[    0.154154] iommu: Default domain type: Translated
[    0.154175] iommu: DMA domain TLB invalidation policy: strict mode
[    0.156896] SCSI subsystem initialized
[    0.161567] pps_core: LinuxPPS API ver. 1 registered
[    0.161578] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.161601] PTP clock support registered
[    0.163496] vgaarb: loaded
[    0.163828] clocksource: Switched to clocksource dmtimer
[    0.164471] VFS: Disk quotas dquot_6.6.0
[    0.164514] VFS: Dquot-cache hash table entries: 1024 (order 0, 4096 bytes)
[    0.190197] NET: Registered PF_INET protocol family
[    0.190529] IP idents hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.191824] tcp_listen_portaddr_hash hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.191859] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.191875] TCP established hash table entries: 4096 (order: 2, 16384 bytes, linear)
[    0.191921] TCP bind hash table entries: 4096 (order: 4, 65536 bytes, linear)
[    0.192020] TCP: Hash tables configured (established 4096 bind 4096)
[    0.192136] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
[    0.192165] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
[    0.192335] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.194999] RPC: Registered named UNIX socket transport module.
[    0.195021] RPC: Registered udp transport module.
[    0.195027] RPC: Registered tcp transport module.
[    0.195032] RPC: Registered tcp-with-tls transport module.
[    0.195037] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    0.195062] PCI: CLS 0 bytes, default 64
[    0.196405] Initialise system trusted keyrings
[    0.204897] workingset: timestamp_bits=14 max_order=17 bucket_order=3
[    0.206149] NFS: Registering the id_resolver key type
[    0.206213] Key type id_resolver registered
[    0.206220] Key type id_legacy registered
[    0.206271] jffs2: version 2.2. (NAND) (SUMMARY)  © 2001-2006 Red Hat, Inc.
[    0.206676] Key type asymmetric registered
[    0.206691] Asymmetric key parser 'x509' registered
[    0.206756] io scheduler mq-deadline registered
[    0.206767] io scheduler kyber registered
[    0.206836] io scheduler bfq registered
[    0.208374] ledtrig-cpu: registered to indicate activity on CPUs
[    0.214644] Serial: 8250/16550 driver, 6 ports, IRQ sharing enabled
[    0.258244] brd: module loaded
[    0.276610] loop: module loaded
[    0.277538] mtdoops: mtd device (mtddev=name/number) must be supplied
[    0.280505] i2c_dev: i2c /dev entries driver
[    0.281368] cpuidle: enable-method property 'ti,am3352' found operations
[    0.281783] sdhci: Secure Digital Host Controller Interface driver
[    0.281792] sdhci: Copyright(c) Pierre Ossman
[    0.281950] sdhci-pltfm: SDHCI platform and OF driver helper
[    0.282879] Initializing XFRM netlink socket
[    0.283017] NET: Registered PF_INET6 protocol family
[    0.298092] Segment Routing with IPv6
[    0.298178] In-situ OAM (IOAM) with IPv6
[    0.298273] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    0.299189] NET: Registered PF_PACKET protocol family
[    0.299216] NET: Registered PF_KEY protocol family
[    0.299359] Key type dns_resolver registered
[    0.299561] ThumbEE CPU extension supported.
[    0.299579] Registering SWP/SWPB emulation handler
[    0.300019] omap_voltage_late_init: Voltage driver support not added
[    0.300356] SmartReflex Class3 initialized
[    0.326062] Loading compiled-in X.509 certificates
[    0.411663] pinctrl-single 44e10800.pinmux: 142 pins, size 568
[    0.416587] ti-sysc 44e31000.target-module: probe with driver ti-sysc failed with error -16
[    0.437195] ti-sysc 48040000.target-module: probe with driver ti-sysc failed with error -16
[    0.485532] OMAP GPIO hardware version 0.1
[    0.512501] omap_i2c 4819c000.i2c: bus 2 rev0.11 at 400 kHz
[    0.518590] 481a8000.serial: ttyS4 at MMIO 0x481a8000 (irq = 25, base_baud = 3000000) is a 8250
[    0.554111] 48000000.interconnect:segment@200000:target-module@0:mpu@0:fck: device ID is greater than 24
[    0.575909] debugfs: Directory '49000000.dma' with parent 'dmaengine' already present!
[    0.575949] edma 49000000.dma: TI EDMA DMA engine driver
[    0.639226] target-module@4b000000:target-module@140000:pmu@0:fck: device ID is greater than 24
[    0.640835] hw perfevents: enabled with armv7_cortex_a8 PMU driver, 5 (8000000f) counters available
[    0.647286] l3-aon-clkctrl:0000:0: failed to disable
[    0.658992] 44e09000.serial: ttyS0 at MMIO 0x44e09000 (irq = 31, base_baud = 3000000) is a 8250
[    0.659081] printk: legacy console [ttyS0] enabled
[    2.074762] tps65217-pmic: Failed to locate of_node [id: -1]
[    2.080821] tps65217-bl: Failed to locate of_node [id: -1]
[    2.089665] tps65217 0-0024: TPS65217 ID 0xe version 1.2
[    2.095552] omap_i2c 44e0b000.i2c: bus 0 rev0.11 at 400 kHz
[    2.102863] omap_gpio 44e07000.gpio: Could not set line 6 debounce to 200000 microseconds (-22)
[    2.111750] sdhci-omap 48060000.mmc: Got CD GPIO
[    2.116758] sdhci-omap 48060000.mmc: supply pbias not found, using dummy regulator
[    2.125636] sdhci-omap 48060000.mmc: supply vqmmc not found, using dummy regulator
[    2.139457] clk: Disabling unused clocks
[    2.143625] PM: genpd: Disabling unused power domains
[    2.174564] mmc0: SDHCI controller on 48060000.mmc [48060000.mmc] using External DMA
[    2.182946] Waiting for root device /dev/mmcblk0p2...
[    2.347976] mmc0: new high speed SDHC card at address aaaa
[    2.354861] mmcblk0: mmc0:aaaa SS16G 14.8 GiB
[    2.365978]  mmcblk0: p1 p2
[    2.564484] EXT4-fs (mmcblk0p2): recovery complete
[    2.570986] EXT4-fs (mmcblk0p2): mounted filesystem 177e51ae-c648-455b-858f-0f47994a58eb r/w with ordered data mode. Quota mode: none.
[    2.583371] VFS: Mounted root (ext4 filesystem) on device 179:2.
[    2.596309] devtmpfs: mounted
[    2.600671] Freeing unused kernel image (initmem) memory: 1024K
[    2.607352] Run /sbin/init as init process
[    2.783924] EXT4-fs (mmcblk0p2): re-mounted 177e51ae-c648-455b-858f-0f47994a58eb.
Seeding 256 bits without crediting
Saving 256 bits of non-creditable seed for next boot
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
[    4.559506] omap-aes 53500000.aes: OMAP AES hw accel rev: 3.2
[    4.566008] omap-aes 53500000.aes: will run requests pump with realtime priority
[    4.601213] remoteproc remoteproc0: wkup_m3 is available
[    4.653325] at24 0-0050: supply vcc not found, using dummy regulator
[    4.676794] at24 0-0050: 32768 byte 24c256 EEPROM, writable, 1 bytes/write
[    4.786575] omap-mailbox 480c8000.mailbox: omap mailbox rev 0x400
[    4.827598] tps6521x_pwrbutton tps65217-pwrbutton: DMA mask not set
[    4.836579] input: tps65217_pwrbutton as /devices/platform/ocp/44c00000.interconnect/44c00000.interconnect:segment@200000/44e0b000.target-module/44e0b000.i2c/i2c-0/0-0024/tps65217-pwrbutton/input/input0
[    4.926557] omap_rng 48310000.rng: Random Number Generator ver. 20
[    4.933499] random: crng init done
[    4.967633] omap_rtc 44e3e000.rtc: registered as rtc0
[    4.972809] omap_rtc 44e3e000.rtc: setting system clock to 2000-01-01T00:00:00 UTC (946684800)
[    5.039757] omap-sham 53100000.sham: hw accel on OMAP rev 4.3
[    5.046159] omap-sham 53100000.sham: will run requests pump with realtime priority
[    5.099207] am335x-phy-driver 47401300.usb-phy: dummy supplies not allowed for exclusive requests (id=vbus)
[    5.145894] am335x-phy-driver 47401b00.usb-phy: dummy supplies not allowed for exclusive requests (id=vbus)
[    5.211493] usbcore: registered new interface driver usbfs
[    5.217266] usbcore: registered new interface driver hub
[    5.222821] usbcore: registered new device driver usb
[    5.293752] musb-hdrc musb-hdrc.0: MUSB HDRC host driver
[    5.299419] musb-hdrc musb-hdrc.0: new USB bus registered, assigned bus number 1
[    5.350595] usb usb1: New USB device found, idVendor=1d6b, idProduct=0002, bcdDevice= 6.12
[    5.359092] usb usb1: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    5.366443] usb usb1: Product: MUSB HDRC host driver
[    5.371438] usb usb1: Manufacturer: Linux 6.12.34 musb-hcd
[    5.377008] usb usb1: SerialNumber: musb-hdrc.0
[    5.409803] hub 1-0:1.0: USB hub found
[    5.424118] hub 1-0:1.0: 1 port detected
[    5.440692] musb-hdrc musb-hdrc.1: MUSB HDRC host driver
[    5.446340] musb-hdrc musb-hdrc.1: new USB bus registered, assigned bus number 2
[    5.474394] usb usb2: New USB device found, idVendor=1d6b, idProduct=0002, bcdDevice= 6.12
[    5.482751] usb usb2: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    5.490119] usb usb2: Product: MUSB HDRC host driver
[    5.495145] usb usb2: Manufacturer: Linux 6.12.34 musb-hcd
[    5.500662] usb usb2: SerialNumber: musb-hdrc.1
[    5.534881] hub 2-0:1.0: USB hub found
[    5.538800] hub 2-0:1.0: 1 port detected
[    5.574853] omap_wdt: OMAP Watchdog Timer Rev 0x01: initial timeout 60 sec
[    5.636659] remoteproc remoteproc0: powering up wkup_m3
[    5.664274] remoteproc remoteproc0: Direct firmware load for am335x-pm-firmware.elf failed with error -2
[    5.673953] remoteproc remoteproc0: request_firmware failed: -2
[    5.679913] wkup_m3_ipc 44e11324.wkup_m3_ipc: rproc_boot failed
[    5.695216] PM: Cannot get wkup_m3_ipc handle
Starting network: OK

Welcome to Ravi's Pocket Beagle
ravi-beagle login: [    6.164328] musb-hdrc musb-hdrc.1: VBUS_ERROR in a_wait_vrise (80, <SessEnd), retry #3, port1 0008010c

Welcome to Ravi's Pocket Beagle
ravi-beagle login: root
Password:
# ls /
bin         lib         lost+found  opt         run         tmp
dev         lib32       media       proc        sbin        usr
etc         linuxrc     mnt         root        sys         var
#uname -a
Linux ravi-beagle 6.12.34 #4 SMP Sat Feb 28 18:01:55 UTC 2026 armv7l GNU/Linux
```

## 🧩 Phase 7: The "Bill of Materials" (Core Software)
Unlike a desktop Ubuntu image that ships with gigabytes of pre-installed software, this custom Buildroot image was intentionally compiled with only the absolute necessities to boot the hardware and provide a root shell.

Here are the specific core components we chose to include in our operating system:

**1. The Bootloader (U-Boot)**

**Version:** 2024.10

**Role:** Initializes the PocketBeagle's RAM, reads the EEPROM to identify the board, and passes the hardware map (Device Tree) to the kernel.

**Customization:** We specifically disabled the modern Driver Model (DM) timer framework to force a fallback to the legacy AM335x hardware clock, bypassing the err -19 panic.

**2. The Linux Kernel**

**Version:** 6.12.x

**Role**: The core engine that manages the CPU, memory, and hardware drivers.

**Customization**: Compiled using the omap2plus configuration and specifically targeted to use the *am335x-pocketbeagle.dtb* blueprint.

**3. The Init System & Userland (BusyBox)**

**Version**: Default Buildroot stable (e.g., 1.36.x)

**Role**: Acts as the "Swiss Army Knife" of embedded Linux. Instead of installing hundreds of megabytes of standard GNU utilities, we used BusyBox to combine essential commands (ls, cd, cat, grep) into a single, highly optimized 2MB executable.

**The Shell:** We bypassed the heavy bash shell and utilized BusyBox's built-in ash (Almquist shell) for maximum speed and minimal memory footprint, represented by the lightweight # root prompt.

**4. The Filesystem**

**Format**: ext4

**Size**: 256MB

**Role**: The structured "C: Drive" residing on the SD card's second partition (mmcblk0p2), expanded from the default 60MB to comfortably house the modern 6.12.x kernel modules.

### 💡 Pro-Tip for the Future
If you ever go back into `make menuconfig` and start adding a bunch of custom packages (like Python, SSH servers, or text editors), you don't have to write them all down manually!

Buildroot can automatically generate a spreadsheet of every single piece of software inside your image. You just run this command in your buildroot folder:

```Bash
make legal-info
```

It will create a folder called legal-info inside output/ containing a manifest.csv file. That file is your exact, automatically generated Bill of Materials!

---

