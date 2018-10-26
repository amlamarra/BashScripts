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

readarray -t urls < $to_sync

for url in "${urls[@]}"; do
	counter=0
	echo "Now checking to make sure $url is here."
	dirs=( $(find $base -maxdepth 1 -mindepth 1 -type d) )
	while read dir; do
		echo -e "\tIs this it?  $dir"
		cd "$dir"
		if [[ $url == $(git config --get remote.origin.url) ]]; then
			echo -e "\tFOUND IT!  Updating..."
			git pull
			break
		else
			echo -e "\tNo. Continuing..."
			counter=$((counter + 1))
		fi
	done < <(printf '%s\n' "${dirs[@]}")
	num_dirs="${#dirs[@]}"
	if [[ $counter -ge $num_dirs ]]; then
		echo -e "\nRepository not found. Let's get it...\n"
		cd "$base"
		git clone "$url"
	fi
	echo
done
