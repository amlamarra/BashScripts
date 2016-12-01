#!/usr/bin/env bash
# An easy way to manage all of your systemd timers
set -e

# Make sure systemd is installed
command -v systemctl >/dev/null 2>&1 || { echo "I require systemd, but it's not installed.  Aborting." >&2; exit 1; }

# DONE
function disp_usage {
    echo -e "\nUsage:  $0 [-u|--user] OPTION [ARGUMENT]"
    echo -e "For more help:  $0 -h\n"
    exit 1
}

# DONE
function disp_help {
    echo "Usage: $0 [-u|--user] OPTION [ARGUMENT]"
    echo "List, create, modify, & delete Systemd Timers"
    echo "Only use one option at a time (not including -u)"
    echo
    echo "  -u, --user          Deal only with user timers (not run as root)"
    echo "  -h, --help          Display this help dialog"
    echo "  -l, --list          List the current timers"
    echo "  -n, --new           Create a new timer"
    echo "  -e, --enable        Enable timer"
    echo "  -s, --start         Start timer"
    echo "  -S, --stop          Stop timer"
    echo "  -d, --disable       Disable timer"
    echo "  -r, --remove        Remove (delete) timer files"
    echo "                      Will also prompt to delete associated service file"
    
    exit 0
}

# DONE
function list_timers {
    systemctl $user list-timers --all
    exit 0
}

function new_timer {
    name="$1"
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name of timer: " name
        echo
    fi
    
    # Add the .timer extension if the user didn't specify it
    if [[ $(echo $name | rev | cut -d '.' -f 1 | rev) != "timer" ]]; then
        name=""$name".timer"
    fi
    
    # Set the path
    if [[ -n "$user" ]]; then # If the user option is set
        path=$USER_PATH
        mkdir -p $path
    else
        read -p "Path to the timer: (/etc/systemd/system/) " path
        if [[ "$path" == '' ]]; then path="/etc/systemd/system/"; fi
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
        service=""$service".service"
        if [[ ! -e ""$path""$service"" ]]; then
            echo "That service file does not exist in the user service path ("$path")"
            exit 1
        fi
        if [[ ! -n "$user" ]]; then
            read -p "Directory of the service file? ($path) " service_path
            if [[ "$service_path" == '' ]]; then service_path=$path; fi
        else
            service_path="$path"
        fi
        if [[ ! -e ""$service_path""$service"" ]]; then
            echo "The service file does not exist ("$service_path""$service")"
            exit 1
        fi
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
    
    exit 0
}

# DONE
function enable_timer {
    name="$1"
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name of timer: " name
        echo
    fi
    
    # Add the .timer extension if the user didn't specify it
    if [[ $(echo $name | rev | cut -d '.' -f 1 | rev) != "timer" ]]; then
        name=""$name".timer"
    fi
    
    # Try enabling the timer
    systemctl $user enable "$name"
    echo ""$name" has been enabled"
    exit 0
}

# DONE
function start_timer {
    name="$1"
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name of timer: " name
        echo
    fi
    
    # Add the .timer extension if the user didn't specify it
    if [[ $(echo $name | rev | cut -d '.' -f 1 | rev) != "timer" ]]; then
        name=""$name".timer"
    fi
    
    # Try starting the timer
    systemctl $user start "$name"
    echo ""$name" has been started"
    exit 0
}

# DONE
function stop_timer {
    name="$1"
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name of timer: " name
        echo
    fi
    
    # Add the .timer extension if the user didn't specify it
    if [[ $(echo $name | rev | cut -d '.' -f 1 | rev) != "timer" ]]; then
        name=""$name".timer"
    fi
    
    # Try stopping the timer
    systemctl $user stop "$name"
    echo ""$name" has been stopped"
    exit 0
}

# DONE
function disable_timer {
    name="$1"
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name of timer: " name
        echo
    fi
    
    # Add the .timer extension if the user didn't specify it
    if [[ $(echo $name | rev | cut -d '.' -f 1 | rev) != "timer" ]]; then
        name=""$name".timer"
    fi
    
    # Set the path
    if [[ -n "$user" ]]; then # If the user option is set
        path=$USER_PATH
    else
        read -p "Path to the timer: (/etc/systemd/system/) " path
        if [[ "$path" == '' ]]; then path="/etc/systemd/system/"; fi
    fi
    
    # Check if the timer exists
    if [[ ! -e "$path""$name" ]]; then
        echo "That timer ("$path""$name") does not exist"
        exit 1
    else # If so, then disable it
        systemctl $user disable "$name"
        echo ""$name" has been disabled"
    fi
    
    exit 0
}

# DONE
function remove_timer {
    name="$1"
    # Prompt user for the name of the timer
    if [[ -z "$1" ]] || [[ "$1" == -* ]]; then
        read -p "Name of timer: " name
        echo
    fi
    
    # Add the .timer extension if the user didn't specify it
    if [[ $(echo $name | rev | cut -d '.' -f 1 | rev) != "timer" ]]; then
        name=""$name".timer"
    fi
    
    # Set the path
    if [[ -n "$user" ]]; then # If the user option is set
        path=$USER_PATH
    else
        read -p "Path to the timer: (/etc/systemd/system/) " path
        if [[ "$path" == '' ]]; then path="/etc/systemd/system/"; fi
    fi
    
    # Prompt to remove associated service file
    read -p "Remove the associated service file of the same prefix? (y/N) " ans
    if [[ "$ans" == '' ]]; then ans="n"; fi
    ans="$(echo "$ans" | tr '[:upper:]' '[:lower:]')"
    if [[ "$ans" == "y" ]]; then
        prefix=$(echo $name | rev | cut -d '.' -f 2- | rev) # Removing extension
        rm ""$path""$prefix".service"
    fi
    
    rm "$path""$name"
    echo ""$name" has been removed"
    exit 0
}

# If no options are supplied, display usage & exit
if [[ $# == 0 ]]; then disp_usage; fi

# Make sure the user isn't using too many options
if [[ ( "$1" != "-u" && "$1" != "--user" ) && $# -gt 2 ]]; then
    echo -e "\nOnly use one option at a time"
    disp_usage
elif [[ ( "$1" == "-u" || "$1" == "--user" ) && $# -gt 3 ]]; then
    echo -e "\nOnly use one option at a time (not including the user option)"
    disp_usage
fi

USER_PATH="$HOME/.config/systemd/user/"

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
        -s|--start )
            TIMER_NAME="$2"
            start_timer $TIMER_NAME
            shift
            ;;
        -S|--stop )
            TIMER_NAME="$2"
            stop_timer $TIMER_NAME
            shift
            ;;
        -d|--disable )
            TIMER_NAME="$2"
            disable_timer $TIMER_NAME
            shift
            ;;
        -r|--remove )
            TIMER_NAME="$2"
            remove_timer $TIMER_NAME
            shift
            ;;
        * ) disp_usage;;
    esac
    shift
done

# Features to implement:
#   -m | --modify  option
#   Turn cron jobs into timers!
