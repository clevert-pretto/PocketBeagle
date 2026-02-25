---
layout: default
title: "How to setup PocketBeagle, connect via WSL2, share internet"
nav_order: 80
parent: "How-to Articles"
has_children: false
---

# PocketBeagle OSD3358: From Zero to Internet

- Project: Headless Debian 13 Setup via WSL2 Bridge
- Host OS: Windows 11 / Ubuntu 24.04 (WSL2)
- Hardware: PocketBeagle Rev A2 + 16GB SanDisk MicroSD

## 1. Flash the SD Card & Set Password
1. **Download Image:** Get the `am335x-debian-13.3-base-armhf.img.xz` from [BeagleBoard.org](https://beagleboard.org/latest-images).
2. **Flash:** Use **BalenaEtcher** to write the image to your MicroSD card.
3. **Pre-configure Security:** * After flashing, open the `BOOT` partition on your PC.
   * Edit `sysconf.txt`: Uncomment the line `#password=debian` and change it to `password=your_password`.
4. Insert the SD card into the PocketBeagle and connect it via USB.

---

## Step 2: Bridge Hardware to WSL2 (Windows PowerShell)
Since I want WSL2 to manage the board, we use usbipd to "pass through" the USB device from Windows to the Linux VM.

1. Identify the Bus ID:

```PowerShell
usbipd list
```
*Look for 1d6b:0104 UsbNcm Host Device (e.g., BUSID 2-4).*

2. Bind (only first time) and Attach:

```PowerShell
usbipd bind --busid 2-4
usbipd attach --wsl --busid 2-4
```

## Step 3: Configure the WSL2 Gateway (WSL2 Ubuntu)
*Once attached, WSL2 sees the board but the network interface is down.*

1. Find the Interface Name:

```Bash
ip link show
```
*Identify the long name starting with enx... (e.g., enx985dad301627).*

2. Initialize & Bridge (The "Internet Sharing" Magic):

```Bash
# Replace 'enx985dad301627' with your actual interface name
INTERFACE="enx985dad301627"

# 1. Bring interface up and set Gateway IP
sudo ip link set $INTERFACE up

# Assign Gateway IP to WSL2 side
sudo ip addr add 192.168.7.1/24 dev $INTERFACE

# Enable IP Forwarding
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# Setup NAT Routing (Internet Sharing)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $INTERFACE -o eth0 -j ACCEPT
```

## Step 4: Access & Route the PocketBeagle (PocketBeagle Terminal)
Log in and configure the board to use the WSL2 gateway.
1. SSH Login (from WSL2):
```bash
ssh debian@192.168.7.2
```
2. Set Default Gateway:
```bash
sudo ip route add default via 192.168.7.1
```
3. Fix DNS (Permanent):
```bash
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```
## Step 5: Final Update & Toolchain
With internet access established, update the OS and install development tools.

1. Test Connection:
```bash
ping google.com -c 3
```
2. Update & Install Tools:

```bash
sudo apt update
sudo apt install build-essential git -y
```
3. Expand Storage (Claim full SD Card space):

```bash
sudo /opt/scripts/tools/grow_partition.sh
sudo reboot
```

## Appendix : WSL2 Automation Script
#!/bin/bash
# Run this after attaching the device via usbipd in Windows
Save this script in WSL2 as pb_connect.sh to automate Step 3 for future uses
```bash
INTERFACE="enx985dad301627" # Update this if your MAC address changes
GATEWAY="192.168.7.1"

echo "Setting up bridge for $INTERFACE..."
sudo ip link set $INTERFACE up
sudo ip addr add $GATEWAY/24 dev $INTERFACE 2>/dev/null
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $INTERFACE -o eth0 -j ACCEPT
echo "Bridge active. SSH into board: ssh debian@192.168.7.2"
```

## Quick checks on Beagle after running above script
1. check your nameserver
```bash 
cat /etc/resolv.conf
```
2. If you don't see nameserver 8.8.8.8 or nameserver 1.1.1.1, the board is blind to the web. Force a DNS server into the configuration:
```bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```
3. The Beagle needs to know that your PC is its "Gateway" to the outside world.
```bash
ip route
```
4. ou should see a line starting with default via 192.168.7.1 (assuming 192.168.7.1 is your PC's IP on that bridge).

If the default route is missing, add it:
```bash
sudo ip route add default via 192.168.7.1
```
5. Now try `ping -c 3 8.8.8.8`. If it works, try `ping google.com`. If the IP works but the name fails, your DNS is still blocked.

---