#!/bin/bash
set -e

# Check required variable
if [ -z "$WAN_IF" ]; then
  echo "Error: WAN_IF environment variable is not set."
  exit 1
fi

# Default ICMP_ALLOW to allow all if not provided
if [ -z "$ICMP_ALLOW" ]; then
  ICMP_ALLOW="0.0.0.0/0"
fi

echo "Flushing any existing IP address on $WAN_IF..."
ip addr flush dev "$WAN_IF"

echo "Obtaining IP via DHCP on interface $WAN_IF..."
dhclient "$WAN_IF"
sleep 5  # Allow time for DHCP lease

echo "Enabling IPv4 forwarding..."
sysctl -w net.ipv4.ip_forward=1

echo "Flushing existing NAT rules..."
iptables -t nat -F

echo "Setting up masquerading on interface $WAN_IF..."
iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE

# Process each forwarding rule (space-separated)
if [ -n "$FORWARD_RULES" ]; then
  for rule in $FORWARD_RULES; do
    # Split rule by colon into protocol, wan_port, dest_ip, and dest_port.
    IFS=':' read -r proto wan_port dest_ip dest_port <<< "$rule"
    if [ -z "$proto" ] || [ -z "$wan_port" ] || [ -z "$dest_ip" ] || [ -z "$dest_port" ]; then
      echo "Skipping invalid rule: $rule"
      continue
    fi

    echo "Setting DNAT for $proto on $WAN_IF: forward port $wan_port to $dest_ip:$dest_port"
    if [ "$proto" == "tcp" ]; then
      iptables -t nat -A PREROUTING -i "$WAN_IF" -p tcp --dport "$wan_port" -j DNAT --to-destination "$dest_ip:$dest_port"
      iptables -A FORWARD -p tcp -d "$dest_ip" --dport "$dest_port" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    elif [ "$proto" == "udp" ]; then
      iptables -t nat -A PREROUTING -i "$WAN_IF" -p udp --dport "$wan_port" -j DNAT --to-destination "$dest_ip:$dest_port"
      iptables -A FORWARD -p udp -d "$dest_ip" --dport "$dest_port" -j ACCEPT
    else
      echo "Unsupported protocol in rule: $rule"
    fi
  done
fi

# Allow established and related connections.
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Set up ICMP rules: allow echo requests from allowed CIDRs on WAN_IF.
for cidr in $ICMP_ALLOW; do
  echo "Allowing ICMP echo-request from $cidr on $WAN_IF"
  iptables -A INPUT -i "$WAN_IF" -p icmp --icmp-type echo-request -s "$cidr" -j ACCEPT
done

echo "Firewall container setup complete. NAT and port forwarding are active."
# Keep the container running indefinitely.
tail -f /dev/null
