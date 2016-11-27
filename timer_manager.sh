#!/usr/bin/env bash
# An easy way to manage all of your systemd timers

# Make sure systemd is installed
command -v systemctl >/dev/null 2>&1 || { echo "I require systemd, but it's not installed.  Aborting." >&2; exit 1; }

# If no arguments are supplied, display usage & exit
if [[ $# == 0 ]]; then
    echo "Usage: ./timer-manager.sh [-u|--user] OPTION [ARGUMENT]"
    exit 1
fi

USER_PATH="$HOME/.config/systemd/user/"

function disp_help {
    echo "Usage: ./timer-manager.sh [-u|--user] OPTION [ARGUMENT]"
    echo "List, create, modify, & delete Systemd Timers"
    echo
    echo "  -h, --help          Display this help dialog"
    echo "  -l, --list          List the current timers"
    echo "  -n, --new           Create a new timer"
    echo "  -e, --enable        Enable timer"
    echo "  -d, --disable       Disable timer"
    echo "  -r, --remove        Remove (delete) timer"
    echo "  -u, --user          Deal only with user timers (not run as root)"
    
    exit 0
}

function list_timers {
    if [[ -n ${user+x} ]]; then
        systemctl --user list-timers --all
    else
        systemctl list-timers --all
    fi
    exit 0
}

function new_timer () {
    # Set the working directory for our files
    if [[ -n ${user+x} ]]; then # If the user option is set
        path=$USER_PATH
        mkdir -p $path
    else
        path="/etc/systemd/system/"
    fi
    
    # If the name argument was not supplied, then prompt for it
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name the timer: " name
    else
        name="$1"
    fi
    echo -e "Let's create a new timer called \""$name"\"\n"
    timer_path=$path
    timer_file=""$timer_path""$name".timer"
    
    # Prompt the user to see if we need to set the Unit= option.
    while [[ $existing != 'y' ]] && [[ $existing != 'n' ]]
    do
        read -p "Will this timer control an existing service? (y/N) " existing
        existing="$(echo "$existing" | tr '[:upper:]' '[:lower:]')"
        if [[ "$existing" == '' ]]; then existing="n"; fi
    done
    # If yes, then gather more information
    if [[ $existing == 'y' ]]; then
        read -p "Name of the existing service (leave off the .service): " service
        echo
        if [[ -n ${user+x} ]]; then 
            while [ ! -e ""$path""$service".service" ]
            do
                echo "That service file does not exist in the user service path ("$path")"
                read -p "Enter the name again (leave off the .service): " service
            done
            service_path="$path"
            echo
        else
            read -p "Directory of the service file? ($path) " service_path
            if [[ "$service_path" == '' ]]; then service_path=$path; fi
            while [ ! -e ""$service_path""$service".service" ]
            do
                echo "The service file does not exist in that directory ("$service_path")"
                read -p "Enter the directory again: " service_path
            done
            echo
        fi
        service=""$service".service"
        service_file=""$service_path""$service""
    # If no, then just set the appropriate variables
    elif [[ $existing == 'n' ]]; then
        service=""$name".service"
        service_path="$path"
        service_file=""$service_path""$service""
    fi
    
    # Ask the user for the description & add it to the .timer file
    read -p "<"$name".timer> Description: " desc
    echo -e "[Unit]\nDescription="$desc"\n\n[Timer]" > $timer_file
    
    # Add the Unit= option to the timer file if necessary
    if [[ $service != $name ]]; then
        echo "Unit="$service_file"" >> $timer_file
    fi
    
    exit
}

while [[ $# > 0 ]]; do
    key="$1"
    case $key in
        -u|--user ) user=1;;
        -h|--help ) disp_help;;
        -l|--list ) list_timers;;
        -n|--new )
            DATETIME="$2"
            new_timer $DATETIME
            shift
            ;;
        * ) echo "Invalid syntax";;
    esac
    shift
done
