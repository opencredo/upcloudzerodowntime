#!/bin/bash
set -e
set -u

METADATA_COMMAND="curl --max-time 1 -s http://169.254.169.254/metadata/v1.json"

echo "Started getting floating IPs"
if [[ ! -e /etc/network/interfaces.d/floating_ip ]]; then
  echo "Getting metadata..."
  ifaces=$($METADATA_COMMAND | jq '.network | .interfaces[] | select( .ip_addresses[] | .floating == true)')
  while [[ -z "$ifaces" ]]; do
    echo "Getting metadata..."
    ifaces=$($METADATA_COMMAND | jq '.network | .interfaces[] | select( .ip_addresses[] | .floating == true)')
    echo "Sleeping"
    sleep 1
  done

  echo "Got metadata"
  ip_address=$(echo $ifaces | jq '.network | .interfaces[] | .ip_addresses[] | select(.floating == true) | .address' -r)
  echo "IP Address $ip_address"

  echo <<EOF > /etc/network/interfaces.d/floating_ip
auto eth0:1
iface eth0:1 inet static
address $ip_address
netmask 255.255.255.255
EOF

  systemctl restart networking.service
fi

