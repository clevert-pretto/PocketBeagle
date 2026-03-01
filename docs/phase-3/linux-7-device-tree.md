---
title: "Module 06: Device tree basics"
parent: "Phase 3 : Understanding Device tree"
nav_order: 1
---

# Basic of Device Trees

## 🌳 What is a Device Tree?
In the old days (pre-2012), every ARM board had its hardware details hard-coded in C structs inside the Linux kernel source. This made the kernel massive and messy.

The Device Tree was introduced to move the "Hardware Description" out of the kernel binary and into a standalone Data Structure.

A Device Tree is a tree-like data structure that describes the non-discoverable hardware components of a system (like I2C, SPI, and GPIO) to the operating system, allowing one single kernel binary to run on many different hardware platforms just by swapping the Device Tree file.

## 🛠️ The Three Files You Must Know
The "Workflow" of a Device Tree:
| File Extension |Name | Purpose |
|----------------|-----|---------|
|.dtsi| Device Tree Include | The "Header" file. Contains shared hardware info (like the internal registers of the AM335x chip).|
.dts | Device Tree Source | The "Recipe." Specific to the PocketBeagle. It includes the .dtsi and defines what's actually connected (LEDs, Header pins).|
|.dtb | Device Tree Blob | The "Executable." This is the binary file U-Boot loads into RAM for the kernel to read.|


## 🔍 Basics of Device Tree Syntax
A Device Tree is made of Nodes and Properties. Think of it like a JSON file for hardware.

1. The Root Node (`/`)
Every DT starts with a root node. Inside, it must have a compatible string. This is how the kernel knows if it’s running on the right board.

```DTS
/ {
    model = "TI AM335x PocketBeagle";
    compatible = "ti,am335x-pocketbeagle", "ti,am33xx";
};
```

2. Properties (The Key-Value Pairs)
`reg:` The physical memory address of the hardware registers.

`status:` Can be "okay" or "disabled". 
(This is do you turn off a UART port without recompiling the kernel?" by Changing status = "disabled" in the DT).

`interrupts:` Defines which IRQ line the hardware uses.

3. Phandles ( `P`ointer to `handle` = `phandle`??)
If a peripheral (like an LED) needs to use a GPIO controller, it uses a phandle to point to that controller. It looks like this: `&gpio1`.

## 💡 Practical Exercise: Finding DT on the Beagle
Since you have a login prompt, you can actually see the "Live" device tree that the kernel is currently using.

Run this command on your PocketBeagle terminal:

```Bash
ls /proc/device-tree/
```
You will see folders for every hardware component. If you `cat` a file in there, you are reading the hardware description directly from the kernel's memory!


## 📄Device Tree Compiler (dtc)
Sometimes, you might have a binary .dtb file but no access to the original source code. How do you verify the hardware configuration of a compiled kernel image?

The answer is **Decompilation**. You can use the `dtc` tool to turn that binary blob back into a human-readable text file.

On your PocketBeagle terminal:
You already have your binary blob sitting in your boot partition. Let's decompile it:

```Bash
# 1. Install the tool (if Buildroot didn't include it, it's usually in 'dtc' package)
# In our current minimal build, we usually run this on the HOST (Ubuntu/WSL)

# 2. Decompile the binary (.dtb) to source (.dts)
dtc -I dtb -O dts -o /tmp/pocketbeagle_extracted.dts /boot/am335x-pocketbeagle.dtb
```
- -I dtb: Input format is Device Tree Blob.

- -O dts: Output format is Device Tree Source.

## 🗺️The Memory Map
Now, How does the Device Tree know where the GPIO registers are located in the CPU memory

It doesn't define them in the `.dts`. It "Includes" them from the `.dtsi` (Include) file provided by the chip manufacturer (TI). If you look at `am33xx.dtsi`, you’ll find the base address:

```DTS
gpio1: gpio@4804c000 {
    compatible = "ti,omap4-gpio";
    reg = <0x4804c000 0x1000>; // Base Address and Range
    interrupts = <98>;
    gpio-controller;
    #gpio-cells = <2>;
};
```
When our LED node says `&gpio1`, it is essentially "pointing" to that memory address `0x4804c000`.

---

# Customisation in device tree and verification

## Injecting a "Dummy" Hardware Node
We are going to manually edit your decompiled (In above steps) `pocketbeagle_extracted.dts`, add a custom node, and recompile it.

**1. Step 1: Edit the Source**
Open your `pocketbeagle_extracted.dts` on your Ubuntu/WSL host. Scroll to the very bottom, just before the final }; closing brace, and add this "Interview Node":

```DTS
	/* Custom Hardware Node for Interview Demo */
	my_custom_device {
		compatible = "ravi,interview-chip-v1";
		status = "okay";
		interview-id = <0x1234abcd>;
		description = "This node proves I can modify the BSP";
	};
```

**Step 2: Recompile the DTB**
Now, we use the dtc tool in reverse. We turn the text (.dts) back into a binary blob (.dtb) that the kernel can read.

```Bash
dtc -I dts -O dtb -o am335x-pocketbeagle.dtb pocketbeagle_extracted.dts
```

**Step 3: Deploy to the PocketBeagle**
1. Copy this new `am335x-pocketbeagle.dtb` to your SD card's boot partition (the same place the original one lives).

2. Boot the PocketBeagle.

**Step 4: Verification**
Once you log in as root, run this command:

```Bash
ls /sys/firmware/devicetree/base/my_custom_device/
```
If you see your description and `custom-id` files there, congratulations! you have successfully modified the hardware architecture of a running Linux system.

---


