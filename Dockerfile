FROM debian:bookworm-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    iptables \
    iproute2 \
    isc-dhcp-client \
    curl \
 && rm -rf /var/lib/apt/lists/*

# Copy entrypoint into the image
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
