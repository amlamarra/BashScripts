#!/usr/bin/env bash
# Display all available cipher suites from a hosted web server

read -rp "Enter the IP or domain name: " domain
# OpenSSL requires the port number.
SERVER="$domain":443

ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo "Obtaining cipher list from $(openssl version)."

for cipher in "${ciphers[@]}"; do
    result=$(echo -n | openssl s_client -cipher "$cipher" -connect "$SERVER" 2>&1)

    if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    :" ]]; then
        echo "$cipher"
    fi

    sleep 1
done
