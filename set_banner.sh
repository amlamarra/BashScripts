#!/usr/bin/env bash

########################################################################
## Title:        set_banner.sh
## Description:  Deploys (or removes) the login banner
## Author:       Andrew Lamarra
## Created:      2/5/2018
## Dependencies: bash, ssh, sshpass
## Usage:        $ sudo ./set_banner.sh [-u|--undo]
########################################################################

#------------------------------------------
# VARIABLES
#------------------------------------------
# Name of the file containing each hosts/IP
hosts=hosts.txt
# URL to download the banner tar file from
bannerURL="http://fileweb/Software/banner.tar"
# Total hosts
total=$(sed '/^#/d' "$hosts" | wc -l)

#------------------------------------------
# SETUP
#------------------------------------------
# Check for the required files
if [ ! -f hosts.txt ]; then
    echo "Place the hosts.txt file in the same directory as the script."
    echo "    This is a list of hostnames or IPs to execute this script on"
    echo "    Each hostname/IP should be separated by a newline"
    echo "    Hostnames/IPs can be commented out with a # at the start of the line"
    exit 1
fi

# Make sure sshpass is installed
command -v sshpass >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "sshpass not installed, installing now...\n"
    sudo apt install -y sshpass || { echo -e "\nInstall failed!\n"; exit 1; }
fi

# Get the remote account to use
read -rp "Enter the username of the remote account to use: " user

# Get the admin password
read -rp "Enter the password for $user: " -s SSHPASS
export SSHPASS
printf "\n\n"

# Clean up from previous runs of this script
rm -f completed.txt failed.txt

#------------------------------------------
# EXECUTION
#------------------------------------------
# Counter for our progress indicator
i=1
while read host; do
    printf "Progress: %3s out of $total hosts\r" "$i"
    i=$((i + 1))

    # Test for connectivity
    ping -c1 -W1 "$host" >/dev/null 2>&1 || { echo "$host failed ping response" >> failed.txt; continue; }


    case $1 in
    # Run this if the -u or --undo option was set
    "-u"|"--undo")
        # Put everything back the way it was
        sshpass -e ssh -o StrictHostKeyChecking=no \
                -o UserKnownHostsFile=/dev/null \
                "${user}@${host}" >/dev/null 2>&1 << EOF
            if [ -f /etc/issue.orig ]; then echo "$SSHPASS" | sudo -S mv -f /etc/issue.orig /etc/issue; fi
            echo "$SSHPASS" | sudo -S sed -i '/^Banner \/etc\/issue$/d' /etc/ssh/sshd_config
            echo "$SSHPASS" | sudo -S rm -f /etc/X11/xinit/xinitrc.d/10aup /etc/X11/Xsession.d/10aup
            if [ -f /etc/centos-release ]; then
                echo "$SSHPASS" | sudo -S service sshd restart
            else
                echo "$SSHPASS" | sudo -S service ssh restart
            fi
EOF
        ;;

    # Run this if the -u or --undo option was not set
    *)
        # Execute the necessary commands on the remote machine
        sshpass -e ssh -o StrictHostKeyChecking=no \
                -o UserKnownHostsFile=/dev/null \
                "${user}@${host}" >/dev/null 2>&1 << EOF
            wget $bannerURL
            if [ ! -f /etc/issue ]; then echo "$SSHPASS" | sudo -S touch /etc/issue; fi
            if [ ! -f /etc/issue.orig ]; then echo "$SSHPASS" | sudo -S mv -f /etc/issue /etc/issue.orig; fi
            echo "$SSHPASS" | sudo -S tar xf banner.tar -C /
            rm -f banner.tar
            if ! grep "^Banner /etc/issue$" /etc/ssh/sshd_config; then
                echo "$SSHPASS" | sudo -S bash -c "echo 'Banner /etc/issue' >> /etc/ssh/sshd_config"
            fi
            if [ -f /etc/centos-release ]; then
                echo "$SSHPASS" | sudo -S mv -f /etc/10aup /etc/X11/xinit/xinitrc.d
                if ! command -v zenity >/dev/null 2>&1; then
                    echo "$SSHPASS" | sudo -S yum install -y zenity
                fi
                echo "$SSHPASS" | sudo -S service sshd reload
            else
                echo "$SSHPASS" | sudo -S mv -f /etc/10aup /etc/X11/Xsession.d
                if ! command -v zenity >/dev/null 2>&1; then
                    echo "$SSHPASS" | sudo -S apt install -y zenity
                fi
                echo "$SSHPASS" | sudo -S service ssh reload
            fi
EOF
        ;;
    esac

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
