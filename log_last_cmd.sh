#!/usr/bin/env bash

# log_last_cmd.sh
# PURPOSE: Logs the last command from the .bash_history file to operator notes.
# AUTHOR:  Lt Andrew Lamarra
# CREATED: 28 OCTOBER 2017
# NOTES & INSTRUCTIONS:
#   These commands need to be executed before anything else:
#     export PROMPT_COMMAND="history -a; history -c; history -r"
#     export HISTTIMEFORMAT="%T  "
#   Also, put these commands in your .bashrc file.
#
#   I also recommend creating an alias (which can also be added to .bashrc):
#     alias log='~/loglast.sh'
#   Or just copy the script to a location in your PATH variable:
#     sudo cp loglast.sh /usr/local/sbin/log
#
#   If you'd like to save your previously run command to your operator notes,
#   run the script & supply 2 arguments, the PAA # and the target IP/network.
#   EXAMPLE:
#     $ nmap -sn 192.168.1.0/24
#     $ log 1 192.168.1.0/24

if [ $# -lt 2 ]; then
    echo "Usage: $0 <PAA #> <Target IP(s)>"
    exit 1
fi

notes="op_notes_$(date +"%Y%m%d").txt"
if [ ! -f $notes ]; then
    echo DATE: $(date +"%d %b %Y") > ~/$notes
        # | 80 Characters wide -->
    echo "+----------+-----+------------------------+------------------------------------+" >> ~/$notes
    echo "|   Time   | PAA |      Target IP(s)      | Command                            |" >> ~/$notes
    echo "+----------+-----+------------------------+------------------------------------+" >> ~/$notes
else
    head -n -1 $notes > temp.txt ; mv -f temp.txt $notes
fi

cmd=$( tail -n1 ~/.bash_history )
epoch=$( tail -n2 ~/.bash_history | head -n1 | cut -d'#' -f2 )
tstamp=$( date -d @$epoch +%T )

printf "| %8s | %2s  | %-22s | %s\n" $tstamp "$1" "$2" "$cmd" >> ~/$notes
echo "+----------+-----+------------------------+------------------------------------+" >> ~/$notes
