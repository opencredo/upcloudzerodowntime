#!/bin/bash
set -e
set -u

METADATA_COMMAND="curl --max-time 1 -s http://169.254.169.254/metadata/v1.json"

echo "Started getting floating IPs"
if [[ ! -e /etc/network/interfaces.d/floating_ip ]]; then
  echo "Getting metadata..."
  ifaces=""
  while [[ -z "$ifaces" ]]; do
    sleep 0.1
    echo "Getting metadata..."
    text=$($METADATA_COMMAND || true)
    if [[ "$text" != "Metadata not available." && ! -z "$text" ]]; then
      ifaces=$(echo $text | jq '.network | .interfaces[] | select( .ip_addresses[] | .floating == true)')
    fi
    echo "Sleeping"
  done

  echo "Got metadata"
  echo $ifaces
  ip_address=$(echo $ifaces | jq '.ip_addresses[] | select(.floating == true) | .address' -r)
  echo "IP Address $ip_address"

  cat <<EOF > /etc/network/interfaces.d/floating_ip
auto eth0:1
iface eth0:1 inet static
address $ip_address
netmask 255.255.255.255
EOF

  systemctl restart networking.service
fi
