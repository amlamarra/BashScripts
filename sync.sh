#!/usr/bin/env bash
#########################################################################
## Title:        sync.sh
## Description:	 Syncs multiple git repositories in ~/tools/ based on the
##               ~/tools/list.txt file. Put each repo URL in there.
## Author:       Andrew Lamarra
## Created:      10/26/2018
## Dependencies: bash (v4.0+), git
#########################################################################

to_sync=~/tools/list.txt
base=~/tools

urls=""
# Get the list of Git repos in list.txt
readarray -t urls < $to_sync

# Get the list of directories in ~/tools/
dirs=( $(find $base -maxdepth 1 -mindepth 1 -type d) )

function repo_not_found {
	#echo -e "\nRepository not found. Let's get it...\n"
	echo -e "A repo in your list.txt file was not found."
	read -rp "Would you like to clone it? (Y/n) " ans
	ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	if [[ $ans == '' ]]; then ans="Y"; fi
}

for url in "${urls[@]}"; do
	counter=0
	echo "Now checking to make sure $url is here."
	
	# Print the current state of the $dirs variable
	echo -e "\n\tCurrent dirs array:"
	for i in "${dirs[@]}"; do echo -e "\t\t$i"; done
	echo

	while read dir; do
		# Save the current number of elements in the dirs array
		num_dirs="${#dirs[@]}"

		echo -e "\tIs this it?  $dir"
		cd "$dir"
		if [[ $url == $(git config --get remote.origin.url) ]]; then
			echo -e "\tFOUND IT!  Updating..."
			#git pull
			# Remove the found directory
			unset "dirs[$counter]"
			break 1
		else
			echo -e "\tNo. Continuing..."
			counter=$((counter + 1))
		fi
	done < <(printf '%s\n' "${dirs[@]}")

	echo -e "\tCounter = $counter\n"

	if [[ $counter -ge $num_dirs ]]; then
		repo_not_found "$url"
	fi

	# Print the current state of the $dirs variable
	echo -e "\tCurrent dirs array:"
	for i in "${dirs[@]}"; do echo -e "\t\t$i"; done
	echo
done
