---
layout: default
title: "Phase 3 : Understanding Device tree"
nav_order: 4
has_children: true
---

## Time to tweak buildroot and linux compilation process

I'm getting overwhelmed with working on this repository and linux, buildroot clones at one place, so here is what I did. 

I use the `OVERRIDE_SRCDIR` mechanism. By creating a `local.mk` file, I point Buildroot to my local Git repository of the kernel. This allows me to use my favorite IDE to edit code and immediately run `make linux-rebuild` without the overhead of creating patches or re-downloading source code for every iteration.

1. Moved the entire 'linux' and 'buildroot' side-by-side to separate folder, outside this repository's scope.

2. Created a local.mk file inside buildroot' root directory and added this line to it,
```bash
LINUX_OVERRIDE_SRCDIR = $(TOPDIR)/../linux
```

3. Abve change will allow buildroot to override the standard download process without touching the complex internal scripts.

Here onwards build process will be straghtforward,
1. I make changes in linux kernel

2. buildroot will take care of compiling and geenrating image for SD card, by running following command,
```bash
# This step is needed for first time as we previoously downloaded the kernel from a URL(or from tarball), it has a "stamp" file saying "I am already done with the kernel." We need to break that stamp so it sees new local.mk.
make linux-dirclean

# Next time onwards, just rebuild will work.
make linux-rebuild
```

3. You should see a line that looks exactly like this:
`>>> linux custom Syncing from source dir ../linux`
If you see that "Syncing" message, you have won. Buildroot is now officially "tethered" to your local Linux folder. Any change you make in `../linux/arch/arm/boot/dts/...` will be picked up every time you run `make linux-rebuild`.


