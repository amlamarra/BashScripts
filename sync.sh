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
urls=()

# Get the list of Git repos in list.txt
readarray -t urls < $to_sync

# Get the list of directories in ~/tools/
dirs=( $(find $base -maxdepth 1 -mindepth 1 -type d) )
untracked=("${dirs[@]}")

function dir_not_found {
	repo_url="$1"

	echo "The following repository was found in your list but not in the $base/ directory:"
	echo -e "\t$repo_url"

	# Ask the user about cloning the repo (and repeat if input is invalid)
	ans=''
	while [[ $ans != 'y' ]] && [[ $ans != 'n' ]]; do
		read -rp "Would you like to clone it? (Y/n) " ans
		if [[ $ans == '' ]]; then ans="y"; fi
		ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	done

	# Clone the repo if the user answers 'yes'
	if [[ $ans == 'y' ]]; then
		cd "$base"
		git clone "$repo_url"
		return
	fi

	# Ask the user if they'd like to remove that repo from the list
	ans=''
	while [[ $ans != 'y' ]] && [[ $ans != 'n' ]]; do
		read -rp "Would you like to remove this repo from your $list file? (Y/n) " ans
		if [[ $ans == '' ]]; then ans="y"; fi
		ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	done

	# If 'yes' then delete the line from the list of repos
	if [[ $ans == 'y' ]]; then
		user=$(echo "$repo_url" | cut -d/ -f4)
		repo=$(echo "$repo_url" | cut -d/ -f5)
		sed -i "/$user\/$repo/d" $to_sync
	fi
}

function repo_not_found {
	repo_url="$1"
	local_dir="$2"

	echo "The following repository was found in $local_dir/ but not your list:"
	echo -e "\t$repo_url"

	# Ask the user about adding it to the list
	ans=''
	while [[ $ans != 'y' ]] && [[ $ans != 'n' ]]; do
		read -rp "Would you like to add it to your $list file? (Y/n) " ans
		if [[ $ans == '' ]]; then ans="y"; fi
		ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	done
	
	if [[ $ans == 'y' ]]; then
		echo "$repo_url" >> "$to_sync"
		return
	fi
	
	# Ask the user if they'd like to remove that repo from the list
	ans=''
	while [[ $ans != 'y' ]] && [[ $ans != 'n' ]]; do
		read -rp "Would you like to remove the repository ($local_dir)? (Y/n) " ans
		if [[ $ans == '' ]]; then ans="y"; fi
		ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	done

	# If 'yes' then delete the directory
	if [[ $ans == 'y' ]]; then
		rm -rf "$local_dir"
	fi
}

# Iterate over the repos found in the list
for url in "${urls[@]}"; do
	counter=0
	
	for dir in "${dirs[@]}"; do
		# Save the current number of elements in the dirs array
		num_dirs="${#dirs[@]}"

		cd "$dir"
		if [[ $url == $(git config --get remote.origin.url) ]]; then
			git pull
			# Remove the found directory
			unset "untracked[$counter]"
			break
		fi
		counter=$((counter + 1))
	done

	if [[ $counter -ge $num_dirs ]]; then
		dir_not_found "$url"
		echo
	fi
done

# Iterate through leftover dirs to see if any are repos not in the list
for dir in "${untracked[@]}"; do
	cd "$dir"
	url=$(git config --get remote.origin.url)
	if [[ $? == 0 ]]; then
		repo_not_found "$url" "$dir"
		echo
	fi
done
