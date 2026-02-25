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
