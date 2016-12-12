#!/usr/bin/env bash
# This script will generate a list of random numbers between the 2 numbers
# you designate below (non-repeating) and save them to a separate file.
# These will be used for the last octet in your next IP address.
# It saves the current IP to a file called burnedips in case you need to
# see which IPs you've already used. Then it changes the IP address and
# updates the ips file to remove the first element.

# Checking for file existence
if [ ! -e ips.txt ]; then
    read -rp 'Enter the first 3 octets of the IP: ' first3
    echo "$first3" >> first3.txt
    ip_range_start=3 # Change this value
    ip_range_end=254 # Change this value
    # Set an array full of random numbers between the 2 designated values
    # These numbers will not repeat
    a=( $(shuf -e $(seq $ip_range_start $ip_range_end)) )
    # Save the array to a file
    echo -n "${a[@]}" > ips.txt
fi

# Save the first 3 octets to a variable (first3)
first3=$(cat first3.txt)

# Save the contents of the ips file to an array
addr=( $(cat ips.txt) )

# If there are no more IP addresses, end the script
if [ ${#addr[@]} -eq 0 ]; then
    echo 'You are all out of IP addresses!'
    exit
fi

# Change IP address to the number in the first element of the array
ifconfig eth1 $first3.${addr[0]}

# set default route
route add default gw $first3.1 eth1

# Display new IP address
echo "Your new IP address: $first3.${addr[0]}"
# Save current IP to another file (burnedips.txt) for future reference
echo "$first3.${addr[0]}" >> burnedips.txt

# Delete the first element of the array
addr=( ${addr[@]:0:0} ${addr[@]:1} )

# Overwrite the new array to the ips file
echo -n "${addr[@]}" > ips.txt
echo You have ${#addr[@]} IP addresses left.
