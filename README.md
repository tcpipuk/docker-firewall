# Docker Firewall

Docker Firewall is a lightweight container that manages a dedicated WAN interface using a macvlan network. It is designed for environments like TrueNAS SCALE where you wish to isolate a physical WAN NIC from the host, let the container obtain its IP via DHCP and then handle NAT, port forwarding and ICMP filtering from within the container.

When the container starts it flushes any existing IP on the WAN interface, runs DHCP to obtain an address, enables IP forwarding, and then applies iptables rules to masquerade outbound traffic and forward specified ports. It also allows you to control which source networks can ping the WAN IP.

## Configuration

The container is configured via the following environment variables:

- **WAN_IF**: The name of the WAN interface as seen within the container (typically `eth0` on the macvlan network).  
- **FORWARD_RULES**: A space-separated list of rules in the format `protocol:wan_port:dest_ip:dest_port` (for example:  
  `tcp:443:192.168.1.100:443 udp:53:192.168.1.101:53`).  
- **ICMP_ALLOW**: A space-separated list of CIDRs allowed to receive ICMP echo requests (pings). If omitted, it defaults to `0.0.0.0/0`.

## Usage

Build the image by running:

```bash
git clone https://github.com/tcpipuk/docker-firewall.git
cd docker-firewall
docker build -t docker-firewall .
```

An example Docker Compose file is provided in the repository. This example uses a macvlan network (with your dedicated WAN NIC) so that only the firewall container receives the WAN IP via DHCP. See [docker-compose.yml](./docker-compose.yml) for details.

When running the container, ensure it is started with the NET_ADMIN capability so that it can modify iptables rules.

## License, Contributing and Disclaimer

This project is licensed under the GPLv3. Contributions are welcome via pull requests or by raising issues on GitHub. Please note that this containerised firewall solution is provided "as is" without warranty. It is intended as a lightweight solution for specific use-cases and should be thoroughly tested before production use.
