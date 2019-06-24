#!/usr/bin/env bash

########################################################################
## Title:        push_file.sh
## Description:  Copies a file to multiple remote machines via SCP
##               Can also delete a file via SSH
## Author:       Andrew Lamarra
## Dependencies: bash, ssh, sshpass
########################################################################


#------------------------------------------
# SETUP
#------------------------------------------
# Name of the file containing each hostname/IP
hosts=hosts.txt

function setup {
    # Check for the required files
    if [ ! -f $hosts ]; then
        echo "ERROR: $hosts file not found!"
        echo "Place the $hosts file in the same directory as the script."
        echo "    This is a list of hostnames or IPs to push the file to"
        echo "    Each hostname/IP should be separated by a newline"
        echo "    Hostnames/IPs can be commented out with a # at the start of the line"
        exit 1
    fi
    # Total hosts
    total=$(sed '/^#/d' "$hosts" | wc -l)

    # Make sure sshpass is installed
    if ! command -v sshpass >/dev/null; then
        echo -e "sshpass not installed, installing now...\n"
        sudo apt install -y sshpass || { echo -e "\nInstall failed!\n"; exit 1; }
    fi

    if [[ -n $delete ]]; then
        del="$1"
        echo "Delete option set..."
        echo "File/directory to delete: $del"
    else
        src="$1"
        echo "Local file: $src"
        if [[ -z $2 ]]; then dst="$1"; else dst="$2"; fi
        echo "Dest file:  $dst"
    fi
    echo

    if [[ -n $sudo ]]; then
        echo -e "Sudo option set, running with elevated privileges...\n"
    fi

    # Get credentials for the remote account to use
    read -rp "Enter the username of the remote account to use: " user
    read -rp "Enter the password for $user: " -s SSHPASS
    export SSHPASS
    printf "\n\n"

    # Clean up from previous runs of this script
    rm -f completed.txt failed.txt
}


#------------------------------------------
# DISPLAY HELP
#------------------------------------------
function disp_help {
    echo
    echo "Copy a single file to multiple remote machines or delete a single file"
    echo "NOTES:"
    echo "    If the file already exits on the remote machine, it will be overwritten"
    echo "    If using the sudo option, the destination file will be owned by the 'root' user"
    echo
    echo "Place the $hosts file in the same directory as the script."
    echo "    This is a list of hostnames or IPs to push the file to"
    echo "    Each hostname/IP should be separated by a newline"
    echo "    Hostnames/IPs can be commented out with a # at the start of the line"
    echo
    echo "Usage: $0 [-d|--delete] [-s|--sudo] FILE [DESTINATION]"
    echo "OPTIONS:"
    echo "  -h|--help    Display this help dialog"
    echo "  -d|--delete  Delete the file on the remote machine (use absolute path)"
    echo "  -s|--sudo    Pushes/deletes the file with root privileges"
    echo "  FILE         File to copy or delete (if the -d option is set)"
    echo "  DESTINATION  Where to save the file to on the remote machine"
    echo
    exit 0
}


#------------------------------------------
# EXECUTION
#------------------------------------------
function execute {
    # Run through the setup
    setup "$1" "$2"

    # Counter for our progress indicator
    i=1
    while read -r host; do
        printf "Progress: %3s out of $total hosts\r" "$i"
        i=$((i + 1))

        # Test for connectivity
        ping -c1 -W1 "$host" >/dev/null 2>&1 || {
            echo "$host failed ping response" >> failed.txt
            continue
        }

        options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        if [[ -n $delete ]]; then
            if [[ -n $sudo ]]; then
                echo "$SSHPASS" | sshpass -e ssh -tt $options \
                        "${user}@${host}" \
                        sudo rm -rf "$del" >/dev/null 2>&1
            else
                sshpass -e ssh $options \
                        "${user}@${host}" \
                        rm -rf "$del" >/dev/null 2>&1
            fi
        else
            if [[ -n $sudo ]]; then
                fname="$(echo "$src" | awk -F/ '{print $NF}')"
                sshpass -e scp $options \
                        -r "$src" \
                        "${user}@${host}:~" >/dev/null 2>&1
                echo "$SSHPASS" | sshpass -e ssh -tt $options \
                        "${user}@${host}" \
                        "sudo mv ~/$fname $dst; sudo chown root: $dst" >/dev/null 2>&1
            else
                sshpass -e scp -o StrictHostKeyChecking=no \
                        -o UserKnownHostsFile=/dev/null \
                        -r "$src" \
                        "${user}@${host}:$dst" >/dev/null 2>&1
            fi
        fi

        if [ $? -ne 0 ]; then
            echo "$host failed at SSH" >> failed.txt
            continue
        fi

        # Save hostname to a file noting this host was completed successfully
        echo "$host" >> completed.txt

    # Hosts can be commented out with a hash (#) at the beginning of the line
    done < <(sed '/^#/d' "$hosts")

    printf "\n\n"
    echo "Completed."
    echo "Successful hosts are saved to the 'completed.txt' file."
    echo "Failed hosts are saved to the 'failed.txt' file."
    echo "NOTE: These files will be overwritten upon subsequent runs of this script."

    exit 0
}


# Parsing the arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help ) disp_help;;
        -d|--delete ) delete=true;;
        -s|--sudo ) sudo=true;;
        * ) execute "$1" "$2";;
    esac
    shift
done

disp_help
