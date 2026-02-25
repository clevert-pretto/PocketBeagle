---
layout: default
title: "Repository structure for embedded linux learning with PocketBeagle"
nav_order: 81
parent: "How-to Articles"
has_children: false
---

Here is an optimal repository structure designed to handle both PocketBeagle source code and GitHub Pages documentation seamlessly.

```text
pocketbeagle-linux-mastery/
├── .github/                       # GitHub Actions workflows (optional, for CI/CD)
├── docs/                          # GitHub Pages source (.md files)
│   ├── index.md                   # Main landing page
│   ├── howto-<topic>.md           # How-to pages with topics
│   ├── linux-01-cli-scripting.md  # Your module documentation
│   ├── linux-02-sysfs-hardware.md
│   └── assets/                    # Images, diagrams, or screenshots for your docs
├── phase-1-user-space/
│   ├── 01-cli-scripting/
│   │   └── temp_logger.sh         # Bash script project
│   ├── 02-sysfs-hardware/
│   │   └── sysfs_commands.sh      # Saved reference commands
│   └── 03-cross-compilation/
│       ├── Makefile               # Host-to-Target compilation rules
│       └── blink.c                # User-space C application
├── phase-2-bsp/
│   ├── 04-uboot/
│   │   └── uboot_env.txt          # Backups of your custom bootargs
│   └── 05-buildroot/
│       ├── pocketbeagle_defconfig # Your custom minimal OS configuration
│       └── board/                 # RootFS overlays (custom init scripts, etc.)
├── phase-3-device-tree/
│   ├── 06-device-tree-basics/
│   │   ├── original_pb.dts        # Decompiled original Device Tree
│   │   └── custom_dummy_node.dtsi # Your injected hardware node
│   └── 07-pinmux/
│       └── pb_pwm_overlay.dts     # Pinmux routing configuration
├── phase-4-kernel-space/
│   ├── 08-kernel-module/
│   │   ├── Makefile
│   │   └── hello_world.c          # Basic LKM
│   ├── 09-char-driver/
│   │   ├── Makefile
│   │   └── my_led.c               # ioremap virtual memory driver
│   └── 10-interrupts-capstone/
│       ├── driver/
│       │   ├── Makefile
│       │   └── button_irq.c       # Kernel space interrupt handler
│       └── user_app/
│           ├── Makefile
│           └── monitor_app.c      # User space receiving application
├── phase-5-distributed-systems/   # PRactical project with PiZero and NodeMCU
│   ├── 11-serial-gateway/
│   │   ├── TBD
│   │   └── TBD                   
│   ├── 12-i2c-multimaster-multislave/
│   │   ├── TBD
│   │   └── TBD          
│   ├── 13-mqtt/
│   │   ├── TBD
│   │   └── TBD
│   └── 14-network-socket/
│       ├── TBD
│       └── TBD
├── .gitignore                     # Crucial for keeping compiled binaries out of Git
├── LICENSE                        # Open-source license (e.g., MIT or GPL)
└── README.md                      # High-level overview of the entire repository
```