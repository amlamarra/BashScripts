#!/usr/bin/env bash

#########################################################################
## Title:        update_hosts.sh
## Description:  Updates the /etc/hosts file from the 'address' entries
##               in a dnsmasq config file
## Author:       Andrew Lamarra
## Created:      1/29/2020
## Dependencies: bash awk sed sort uniq
#########################################################################

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

hosts_file=/etc/hosts
dnsmasq_file=/etc/dnsmasq.d/02-custom.conf

cat > $hosts_file << EOF
127.0.0.1       mail.lamarranet.local mail piserve.lamarranet.local piserve localhost localhost.localdomain
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       mail piserve
EOF

grep address=/ $dnsmasq_file \
    | awk -F/ '{printf "%-16s%s\n", $3, $2}' \
    | sed 's/\.lamarranet.*//g' \
    | sort -V \
    | uniq >> $hosts_file
