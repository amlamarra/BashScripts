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
    echo 'List, create, modify, & delete Systemd Timers'
    echo 'Only use one option at a time (not including -u)'
    echo
    echo '  -u, --user          Deal only with user timers (not run as root)'
    echo '  -h, --help          Display this help dialog'
    echo '  -l, --list          List the current timers'
    echo '  -n, --new           Create a new timer'
    echo '  -e, --enable        Enable timer'
    echo '  -s, --start         Start timer'
    echo '  -S, --stop          Stop timer'
    echo '  -d, --disable       Disable timer'
    echo '  -r, --remove        Remove (delete) timer and/or associated service files'
    echo
    exit 0
}

# DONE
function timer_options {
    echo 'AccuracySec='
    echo '    Specify the accuracy the timer shall elapse with. Defaults to 1min.'
    echo
    echo 'RandomizedDelaySec='
    echo '    Delay the timer by a randomly selected, evenly distributed amount of time'
    echo '    between 0 and the specified time value. Defaults to 0, indicating that no'
    echo '    randomized delay shall be applied.'
    echo
    echo 'Persistent=(true|false)'
    echo '    If true, the time when the service was last triggered is stored on disk.'
    echo '    The service unit is triggered immediately if the next run is missed.'
    echo '    This is useful to catch up on missed runs of the service when the machine'
    echo '    was off. Only use with OnCalendar= (realtime timers). Defaults to false.'
    echo
    echo 'WakeSystem=(true|false)'
    echo '    If true, an elapsing timer will cause the system to resume from suspend,'
    echo '    should it be suspended and if the system supports this. Defaults to false.'
    echo
    echo 'RemainAfterElapse=(true|false)'
    echo '    If true, an elapsed timer will stay loaded, and its state remains queriable.'
    echo '    If false, an elapsed timer unit that cannot elapse anymore is unloaded.'
    echo '    Turning this off is particularly useful for transient timer units that shall'
    echo '    disappear after they first elapse. Defaults to true.'
    echo
}

# DONE
function time_syntax {
    echo 'VALUE [UNIT]'
    echo '    If no time unit is specified, seconds are assumed.'
    echo
    echo 'Possible units:'
    echo '    usec, us'
    echo '    msec, ms'
    echo '    seconds, second, sec, s'
    echo '    minutes, minute, min, m'
    echo '    hours, hour, hr, h'
    echo '    days, day, d'
    echo '    weeks, week, w'
    echo '    months, month, M (defined as 30.44 days)'
    echo '    years, year, y (defined as 365.25 days)'
    echo 'Examples:'
    echo '    2 h'
    echo '    2hours'
    echo '    48hr'
    echo '    1y 12month'
    echo '    55s500ms'
    echo '    300ms20s 5day'
    echo
}

# DONE
function calendar_syntax {
    echo 'Examples for valid timestamps and their normalized form:'
    echo
    echo '  Sat,Thu,Mon..Wed,Sat..Sun → Mon..Thu,Sat,Sun *-*-* 00:00:00'
    echo '      Mon,Sun 12-*-* 2,1:23 → Mon,Sun 2012-*-* 01,02:23:00'
    echo '                    Wed *-1 → Wed *-*-01 00:00:00'
    echo '           Wed..Wed,Wed *-1 → Wed *-*-01 00:00:00'
    echo '                 Wed, 17:48 → Wed *-*-* 17:48:00'
    echo 'Wed..Sat,Tue 12-10-15 1:2:3 → Tue..Sat 2012-10-15 01:02:03'
    echo '                *-*-7 0:0:0 → *-*-07 00:00:00'
    echo '                      10-15 → *-10-15 00:00:00'
    echo '        monday *-12-* 17:00 → Mon *-12-* 17:00:00'
    echo '  Mon,Fri *-*-3,1,2 *:30:45 → Mon,Fri *-*-01,02,03 *:30:45'
    echo '       12,14,13,12:20,10,30 → *-*-* 12,13,14:10,20,30:00'
    echo '            12..14:10,20,30 → *-*-* 12,13,14:10,20,30:00'
    echo '  mon,fri *-1/2-1,3 *:30:45 → Mon,Fri *-01/2-01,03 *:30:45'
    echo '             03-05 08:05:40 → *-03-05 08:05:40'
    echo '                   08:05:40 → *-*-* 08:05:40'
    echo '                      05:40 → *-*-* 05:40:00'
    echo '     Sat,Sun 12-05 08:05:40 → Sat,Sun *-12-05 08:05:40'
    echo '           Sat,Sun 08:05:40 → Sat,Sun *-*-* 08:05:40'
    echo '           2003-03-05 05:40 → 2003-03-05 05:40:00'
    echo ' 05:40:23.4200004/3.1700005 → 05:40:23.420000/3.170001'
    echo '             2003-02..04-05 → 2003-02,03,04-05 00:00:00'
    echo '       2003-03-05 05:40 UTC → 2003-03-05 05:40:00 UTC'
    echo '                 2003-03-05 → 2003-03-05 00:00:00'
    echo '                      03-05 → *-03-05 00:00:00'
    echo '                     hourly → *-*-* *:00:00'
    echo '                      daily → *-*-* 00:00:00'
    echo '                  daily UTC → *-*-* 00:00:00 UTC'
    echo '                    monthly → *-*-01 00:00:00'
    echo '                     weekly → Mon *-*-* 00:00:00'
    echo '                     yearly → *-01-01 00:00:00'
    echo '                   annually → *-01-01 00:00:00'
    echo '                      *:2/3 → *-*-* *:02/3:00'
    echo
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
    
    # Creating the timer file & adding the description
    read -p "<"$name"> Description: " Description
    echo -e "[Unit]\nDescription="$Description"\n\n[Timer]" > $timer_file
    
    # What type of timer will this be?
    echo -e '\nRealtime timers will activate at a specific time or day.'
    echo 'Monotonic timers will activate at specific intervals.'
    echo
    echo 'Create a realtime or monotonic timer?'
    PS3='Make a selection: '
    options=("Realtime" "Monotonic")
    select type in "${options[@]}"
    do
        case $type in
            "Realtime") break;;
            "Monotonic") break;;
            *) echo "Invalid option";;
        esac
    done
    echo
    
    # Setting timer frequencies
    if [[ $type == "Monotonic" ]]; then
        echo '(simply enter "s" without quotes to display the syntax)'
        read -p 'How long should the timer wait after boot before being activated? ' OnBootSec
        echo
        
        if [[ "$OnBootSec" == "s" ]]; then
            time_syntax
            read -p 'How long should the timer wait after boot before being activated? ' OnBootSec
        fi
        echo
        read -p 'How frequently should the timer be activated after that? ' OnUnitActiveSec
        echo
        
        # Add this information to the timer file
        echo -e "OnBootSec="$OnBootSec"\nOnUnitActiveSec="$OnUnitActiveSec"" >> $timer_file
    elif [[ $type == "Realtime" ]]; then
        echo '(simply enter "s" without quotes to display the syntax)'
        read -p 'Enter the calendar event expression: ' OnCalendar
        
        if [[ "$OnCalendar" == "s" ]]; then
            calendar_syntax
            read -p 'Enter the calendar event expression: ' OnCalendar
        fi
        echo -e "OnCalendar="$OnCalendar"" >> $timer_file
        echo
    fi
    
    # Prompt user for additional options for the timer
    echo 'Additional timer options:'
    PS3='Make a selection: '
    options=("AccuracySec=" "RandomizedDelaySec=" "Persistent=" "WakeSystem="
        "RemainAfterElapse=" "Display options help" "Done adding options")
    select type in "${options[@]}"
    do
        case $type in
            "AccuracySec=") read -p 'Specify accuracy: (VALUE [UNIT]) ' AccuracySec;;
            "RandomizedDelaySec=") read -p 'Randomized delay: (VALUE [UNIT]) ' RandomizedDelaySec;;
            "Persistent=") Persistent=true; echo 'Adding Persistent=true';;
            "WakeSystem=") WakeSystem=true; echo 'Adding WakeSystem=true';;
            "RemainAfterElapse=") RemainAfterElapse=false; echo 'Adding RemainAfterElapse=false';;
            "Display options help") echo; timer_options;;
            "Done adding options") break;;
            *) echo "Invalid option";;
        esac
    done
    
    if [[ -n "$AccuracySec" ]]; then echo "AccuracySec="$AccuracySec"" >> $timer_file; fi
    if [[ -n "$RandomizedDelaySec" ]]; then echo "RandomizedDelaySec="$RandomizedDelaySec"" >> $timer_file; fi
    if [[ -n "$Persistent" ]]; then echo "Persistent=$Persistent" >> $timer_file; fi
    if [[ -n "$WakeSystem" ]]; then echo "WakeSystem=$WakeSystem" >> $timer_file; fi
    if [[ -n "$RemainAfterElapse" ]]; then echo "RemainAfterElapse=$RemainAfterElapse" >> $timer_file; fi
    
    # Add the Unit= option to the timer file if necessary
    if [[ "$srvc_prefix" != "$timer_prefix" ]]; then
        echo "Unit="$srvc_file"" >> $timer_file
    fi
    
    # Add the [Install] section
    echo -e '\n[Install]\nWantedBy=timers.target' >> $timer_file
    echo -e "\nThe following timer file has been created: "$timer_file"\n"
    
    # CREATING SERVICE FILE
    #if [[ "$existing" == 'n' ]]; then
    #    echo -e "[Unit]\n" > $srvc_file
    #fi
    
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