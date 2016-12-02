#!/usr/bin/env bash
# An easy way to manage all of your systemd timers
set -e
echo

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
    echo
    exit 0
}

# DONE
function list_timers {
    systemctl $user list-timers --all
    echo
    exit 0
}

# DONE
function get_name {
    name="$1"
    # Prompt user for the name of the timer
    if [[ -z "$1" ]]; then
        read -p "Name of timer: " name
        echo
    fi
    
    # Add the .timer extension if the user didn't specify it
    if [[ $(echo "$name" | rev | cut -d '.' -f 1 | rev) != "timer" ]]; then
        timer_prefix="$name"
        name=""$name".timer"
    else
        timer_prefix=$(echo "$name" | rev | cut -d '.' -f 1 | rev)
    fi
}

# DONE
function get_srvc_name {
    srvc_name="$1"
    # Prompt user for the name of the service
    if [[ -z "$1" ]]; then
        read -p "Name of service: " srvc_name
        echo
    fi
    
    # Add the .service extension if the user didn't specify it
    if [[ $(echo "$srvc_name" | rev | cut -d '.' -f 1 | rev) != "service" ]]; then
        srvc_prefix="$srvc_name"
        srvc_name=""$srvc_name".service"
    else
        srvc_prefix=$(echo "$srvc_name" | rev | cut -d '.' -f 1 | rev)
    fi
}

# DONE
function get_path {
    # Set the path
    if [[ -n "$user" ]]; then # If the user option is set
        path=$USER_PATH
    else
        read -p "Path to the timer: (/etc/systemd/system/) " path
        if [[ "$path" == '' ]]; then path="/etc/systemd/system/"; fi
        echo
    fi
}

# DONE
function get_srvc_path {
    # Set the path
    if [[ -n "$user" ]]; then # If the user option is set
        srvc_path=$USER_PATH
    else
        read -p "Path to the service: (/etc/systemd/system/) " srvc_path
        if [[ "$srvc_path" == '' ]]; then srvc_path="/etc/systemd/system/"; fi
        echo
    fi
}

function new_timer {
    get_name $1
    
    get_path
    
    # Create the directory, if necessary
    if [[ -n "$user" ]]; then mkdir -p $path; fi
    
    echo -e "Let's create a new timer called \""$name"\"\n"
    timer_file="$path""$name"
    
    # Prompt the user to see if we need to set the Unit= option.
    while [[ "$existing" != 'y' ]] && [[ "$existing" != 'n' ]]; do
        read -p "Will this timer control an existing service? (y/N) " existing
        existing="$(echo "$existing" | tr '[:upper:]' '[:lower:]')"
        if [[ "$existing" == '' ]]; then existing="n"; fi
        echo
    done
    
    # If yes, then gather more information
    if [[ $existing == 'y' ]]; then
        get_srvc_name
        
        get_srvc_path
        srvc_file = "$srvc_path""$srvc_name"
        
        # If the service file doesn't exist...
        while [[ ! -e "$srvc_file" ]]; do
            echo "That service file does not exist in the default path ("$path")"
            read -p "Would you like to specify a different path? (y/N) " ans
            ans="$(echo "$ans" | tr '[:upper:]' '[:lower:]')"
            if [[ "$ans" == '' ]]; then ans="n"; fi
            if [[ "$ans" == 'y' ]]; then get_srvc_name; else exit 1; fi
        done
        
        if [[ ! -e "$srvc_file" ]]; then
            echo "The service file does not exist ("$srvc_file")"
            exit 1
        fi
    # If no, then just set the appropriate variables
    elif [[ "$existing" == 'n' ]]; then
        srvc_prefix="$timer_prefix"
        srvc_name="$srvc_prefix.service"
        srvc_path="$path"
        srvc_file=""$srvc_path""$srvc_name""
    fi
    
    # Ask the user for the description & add it to the .timer file
    read -p "<"$name"> Description: " desc
    echo -e "[Unit]\nDescription="$desc"\n\n[Timer]" > $timer_file
    
    # Add the Unit= option to the timer file if necessary
    if [[ "$srvc_prefix" != "$timer_prefix" ]]; then
        echo "Unit="$srvc_file"" >> $timer_file
    fi
    
    if [[ "$existing" == 'n' ]]; then
        echo -e "[Unit]\n" > $srvc_file
    fi
    
    echo
    exit 0
}

# DONE
function enable_timer {
    get_name $1
    
    # Try enabling the timer
    systemctl $user enable "$name"
    echo -e ""$name" has been enabled\n"
    
    exit 0
}

# DONE
function start_timer {
    get_name $1
    
    # Try starting the timer
    systemctl $user start "$name"
    echo -e ""$name" has been started\n"
    
    exit 0
}

# DONE
function stop_timer {
    get_name $1
    
    # Try stopping the timer
    systemctl $user stop "$name"
    echo -e ""$name" has been stopped\n"
    
    exit 0
}

# DONE
function disable_timer {
    get_name $1
    
    get_path
    
    # Check if the timer exists
    if [[ ! -e "$path""$name" ]]; then
        echo -e "That timer ("$path""$name") does not exist\n"
        exit 1
    else # If so, then disable it
        systemctl $user disable "$name"
        echo -e ""$name" has been disabled\n"
    fi
    
    exit 0
}

# DONE
function remove_timer {
    get_name $1
    
    get_path
    
    # Prompt to remove associated service file
    while [[ $existing != 'y' ]] && [[ $existing != 'n' ]]; do
        read -p "Remove the associated service file of the same prefix? (y/N) " ans
        ans="$(echo "$ans" | tr '[:upper:]' '[:lower:]')"
        if [[ "$ans" == '' ]]; then ans="n"; fi
    done
    if [[ "$ans" == "y" ]]; then
        prefix=$(echo $name | rev | cut -d '.' -f 2- | rev) # Removing extension
        rm ""$path""$prefix".service"
    fi
    
    rm "$path""$name"
    echo -e ""$name" has been removed\n"
    
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
        -n|--new ) new_timer "$2"; shift;;
        -e|--enable ) enable_timer "$2"; shift;;
        -s|--start ) start_timer "$2"; shift;;
        -S|--stop ) stop_timer "$2"; shift;;
        -d|--disable ) disable_timer "$2"; shift;;
        -r|--remove ) remove_timer "$2"; shift;;
        * ) disp_usage;;
    esac
    shift
done

# Features to implement:
#   -m | --modify  option
#   Turn cron jobs into timers!
