---
title: "Module 08: Pin Multiplexing (Pinmux)"
parent: "Phase 3 : Understanding Device tree"
nav_order: 2
---

# Pin Multiplexing & PWM via Device Tree

## 🎯 Objective
To reconfigure a physical SoC pin from its default State (GPIO) to a specialized Hardware Function (PWM) by modifying the Linux Device Tree and verifying the change at the silicon register level.

## 🏗️ The Hardware Challenge
The TI AM335x SoC on the PocketBeagle uses a "Control Module" to manage pin functions. Each physical pin can be mapped to one of 8 internal modes (Mode 0–7).

For this exercise, we targeted Header Pin P1.36:

- Default State: Mode 7 (GPIO2_2)

- Target State: Mode 3 (EHRPWM0B - Enhanced PWM)

- Register Offset: 0x190

### 🛠️ Step 1: Modifying the Device Tree Source (DTS)
We modified the primary board file located at:

`linux/arch/arm/boot/dts/ti/omap/am335x-pocketbeagle.dts`

1.  Defining the Pinctrl Group
We added a new node within the `&am33xx_pinmux` block to set the physical electrical characteristics of the pin.

```plaintext
&am33xx_pinmux {
    /* Define Mode 3 for Pin P1.36 */
    pwm_p1_36_pins: pinmux_pwm_p1_36_pins {
        pinctrl-single,pins = <
            0x190 0x03  /* Offset 0x190, MUX_MODE3, No Pull-up, Output */
        >;
    };
};
```

2.  Activating the PWM Hardware
We performed a Node Override to enable the PWM controller and link it to our new pin group.

```plaintext
&epwmss0 {
    status = "okay";
};

&ehrpwm0 {
    status = "okay";
    pinctrl-names = "default";
    pinctrl-0 = <&pwm_p1_36_pins>; /* Overrides any previous pin assignment */
};
```

### 🏗️ Step 2: The "Side-by-Side" Build Workflow
To ensure Buildroot used our local Linux source code instead of a downloaded tarball, we utilized the OVERRIDE_SRCDIR mechanism. Described in [Phase 3 : Understanding Device tree](../phase-3.md).

### 🔍 Step 3: Silicon-Level Verification
After booting the new image, we verified that the kernel successfully programmed the SoC registers.

1.  Checking the Raw Register
We queried the debugfs interface to confirm the multiplexer state for offset 0x190.

```Bash
cat /sys/kernel/debug/pinctrl/44e10800.pinmux-pinctrl-single/pins | grep "190"
```
Expected Output: 
`pin 100 (44e10990) 00000003`

(The 3 confirms the pin is successfully in PWM Mode).

2.  Operating the PWM via Sysfs
We controlled the hardware signal directly from user-space using the Linux PWM class driver.

```Bash
# Initialize PWM Channel 1
cd /sys/class/pwm/pwmchip0
echo 1 > export
cd pwm1

# Configure: 1kHz Frequency (1ms period), 50% Duty Cycle
echo 1000000 > period
echo 500000 > duty_cycle
echo 1 > enable
```

**appendix**

- **Node Override** - In DT, the last definition of a label wins. We used `&ehrpwm0` to overwrite the factory pin settings with our custom P1.36 group.

- **pinctrl-single** - The driver that manages the AM335x "Control Module" memory-mapped registers.
