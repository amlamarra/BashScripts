#!/usr/bin/env bash
#########################################################################
## Title:        sync.sh
## Description:	 Syncs multiple git repositories in ~/tools/ based on the
##               ~/tools/list.txt file. Put each repo URL in there.
## Author:       Andrew Lamarra
## Created:      01/23/2019
## Dependencies: bash (v4.0+), git
#########################################################################

# Setup
base=~/tools
list=list.txt
to_sync=$base/$list
cd ~

urls=""
# Get the list of Git repos in list.txt
readarray -t urls < $to_sync

# Get the list of directories in ~/tools/
dirs=( $(find $base -maxdepth 1 -mindepth 1 -type d) )

function dir_not_found {
	echo -e "A repo in your $list file was not found in $base."

	# Ask the user about cloning the repo (and repeat if input is invalid)
	while [[ $ans != 'y' ]] && [[ $ans != 'n' ]]; do
		read -rp "Would you like to clone it? (Y/n) " ans
		if [[ $ans == '' ]]; then ans="y"; fi
		ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	done

	# Clone the repo if the user answers 'yes'
	if [[ $ans == 'y' ]]; then
		cd "$base"
		git clone "$1"
		return
	fi

	# Ask the user if they'd like to remove that repo from the list
	while [[ $ans != 'y' ]] && [[ $ans != 'n' ]]; do
		read -rp "Would you like to remove this repo from your $list file? (Y/n) " ans
		if [[ $ans == '' ]]; then ans="y"; fi
		ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	done

	# If 'yes' then delete the line from the list of repos
	if [[ $ans == 'y' ]]; then
		user=$(echo $repo | cut -d/ -f4)
		repo=$(echo $repo | cut -d/ -f5)
		sed -i "/$user\/$repo/d" $to_sync
	fi
}

function repo_not_found {
	true
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
		dir_not_found "$url"
	fi

	# Print the current state of the $dirs variable
	echo -e "\tCurrent dirs array:"
	for i in "${dirs[@]}"; do echo -e "\t\t$i"; done
	echo
done

