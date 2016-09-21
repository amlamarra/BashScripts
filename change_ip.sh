#!/bin/bash
# This script will generate a list of random numbers between the 2 numbers
# you designate below (non-repeating) and save them to a separate file.
# These will be used for the last octet in your next IP address.
# It saves the current IP to a file called burnedips in case you need to
# see which IPs you've already used. Then it changes the IP address and
# updates the ips file to remove the first element.

# Checking for file existence
if [ ! -e ips ]; then
	echo Enter the first 3 octets of the IP:
        read first3
	echo $first3 >> first3
        ip_range_start=( 3 ) # Change this value
        ip_range_end=( 254 ) # Change this value
	# Set an array full of random numbers between the 2 designated values
	# These numbers will not repeat
        a=( $(shuf -e $(seq $ip_range_start $ip_range_end)) )
	# Save the array to a file
        echo ${a[@]} > ips
fi

# Save the first 3 octets to a variable (first3)
first3=($(cat first3))

# Save the contents of the ips file to an array
addr=($(cat ips))

# If there are no more IP addresses, end the script
if [ ${#addr[@]} -eq 0 ]; then
	echo You are all out of IP addresses!
	exit
fi

# Get the last octet of your current IP address & save to a variable (ip)
ip="$(ifconfig | grep -A 1 'eth1' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1 | cut -d '.' -f 4)"
# Save that to another file (burnedips) for future reference
echo $ip >> burnedips
# Change IP address to the number in the first element of the array
ifconfig eth1 $first3.${addr[0]}
# set default route
route add default gw $first3.1 eth1
# Display new IP address
echo Your new IP address: $first3.${addr[0]}
# Delete the first element of the array
delete=( ${addr[0]} )
output=( ${addr[@]/$delete} )
# Overwrite the new array to the ips file
echo ${output[@]} > ips
echo You have ${#output[@]} IP addresses left.
