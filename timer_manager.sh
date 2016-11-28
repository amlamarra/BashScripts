#!/usr/bin/env bash
# An easy way to manage all of your systemd timers
set -e

# Make sure systemd is installed
#command -v systemctl >/dev/null 2>&1 || { echo "I require systemd, but it's not installed.  Aborting." >&2; exit 1; }

# Output each argument
echo "Arguments ($#):"
for i in $(seq 0 $#); do echo $i = ${!i}; done

function disp_usage {
    echo "Usage: $0 [-u|--user] OPTION [ARGUMENT]"
    echo "For more help: $0 -h"
}

# If no options are supplied, display usage & exit
if [[ $# == 0 ]]; then
    disp_usage
    exit 1
fi

# Make sure the user isn't using too many options
if [[ ( "$1" != "-u" || "$1" != "--user" ) && $# > 2 ]]; then
    echo "Only use one option at a time"
    disp_usage
    exit 1
elif [[ ( "$1" == "-u" || "$1" == "--user" ) && $# > 3 ]]; then
    echo "Only use one option at a time (including the user option)"
    disp_usage
    exit 1
fi

USER_PATH="$HOME/.config/systemd/user/"

function disp_help {
    echo "Usage: $0 [-u|--user] OPTION [ARGUMENT]"
    echo "List, create, modify, & delete Systemd Timers"
    echo
    echo "  -u, --user          Deal only with user timers (not run as root)"
    echo "  -h, --help          Display this help dialog"
    echo "  -l, --list          List the current timers"
    echo "  -n, --new           Create a new timer"
    echo "  -e, --enable        Enable timer"
    echo "  -s, --start         Start timer"
    echo "  -S, --stop          Stop timer"
    echo "  -d, --disable       Disable timer"
    echo "  -r, --remove        Remove (delete) timer"
    
    exit 0
}

function list_timers {
    systemctl $user list-timers --all
    exit 0
}

function new_timer {
    # Set the working directory for our files
    if [[ -n "$user" ]]; then # If the user option is set
        path=$USER_PATH
        mkdir -p $path
    else
        path="/etc/systemd/system/"
    fi
    
    # If the name argument was not supplied, then prompt for it
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name the timer (leave off the .timer extension): " name
    else
        name="$1"
    fi
    echo -e "Let's create a new timer called \""$name"\"\n"
    timer_path=$path
    timer_file=""$timer_path""$name".timer"
    
    # Prompt the user to see if we need to set the Unit= option.
    while [[ $existing != 'y' ]] && [[ $existing != 'n' ]]; do
        read -p "Will this timer control an existing service? (y/N) " existing
        existing="$(echo "$existing" | tr '[:upper:]' '[:lower:]')"
        if [[ "$existing" == '' ]]; then existing="n"; fi
    done
    # If yes, then gather more information
    if [[ $existing == 'y' ]]; then
        read -p "Name of the existing service (leave off the .service extension): " service
        echo
        if [[ -n "$user" ]]; then 
            while [ ! -e ""$path""$service".service" ]; do
                echo "That service file does not exist in the user service path ("$path")"
                read -p "Enter the name again (leave off the .service extension): " service
            done
            service_path="$path"
            echo
        else
            read -p "Directory of the service file? ($path) " service_path
            if [[ "$service_path" == '' ]]; then service_path=$path; fi
            while [ ! -e ""$service_path""$service".service" ]; do
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
    
    # http://man7.org/linux/man-pages/man5/systemd.timer.5.html
    # OPTIONS:
    # OnActiveSec=, OnBootSec=, OnStartupSec=, OnUnitActiveSec=, OnUnitInactiveSec=
    # OnCalendar=
    # AccuracySec=
    # RandomizedDelaySec=
    # Unit=
    
    # filename.timer
    # [Install]
    # WantedBy=timers.target
    exit 0
}

function enable_timer {
    # Set the working directory for our files
    if [[ -n "$user" ]]; then # If the user option is set
        path=$USER_PATH
        mkdir -p $path
    else
        path="/etc/systemd/system/"
    fi
    
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Enter name of timer (leave off the .timer extension): " name
        name=""$name".timer"
    else
        name=""$1".timer"
    fi
    
    # Check for the timer's existence
    #while [ ! -e "$path"$name".timer" ]; do
    #    echo "That timer file does not exist in the default path ($path)"
    #    read -p "Enter the name of the timer again: " name
    #done
    
    systemctl $user enable "$name"
    exit 0
}

function disable_timer {
    # Set the working directory for our files
    if [[ -n "$user" ]]; then # If the user option is set
        path=$USER_PATH
        mkdir -p $path
    else
        path="/etc/systemd/system/"
    fi
    
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Enter name of timer (leave off the .timer extension): " name
        name=""$name".timer"
    else
        name=""$1".timer"
    fi
    
    # Check for the timer's existence
    #while [ ! -e "$path"$name".timer" ]; do
    #    echo "That timer file does not exist in the default path ($path)"
    #    read -p "Enter the name of the timer again: " name
    #done
    
    systemctl $user disable "$name"
    exit 0
}

while [[ $# > 0 ]]; do
    key="$1"
    case $key in
        -u|--user ) user="--user";;
        -h|--help ) disp_help;;
        -l|--list ) list_timers;;
        -n|--new )
            TIMER_NAME="$2"
            new_timer $TIMER_NAME
            shift
            ;;
        -e|--enable )
            TIMER_NAME="$2"
            enable_timer $TIMER_NAME
            shift
            ;;
        -d|--disable )
            TIMER_NAME="$2"
            disable_timer $TIMER_NAME
            shift
            ;;
        * ) disp_usage;;
    esac
    shift
done
