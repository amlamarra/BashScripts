#!/bin/bash -i

# log_last_cmd.sh
# This script will log the last command from the .bash_history file to operator notes.
# Author: Lt Andrew Lamarra
# Date created: 28 OCTOBER 2017

# This needs to be executed before anything else:
# export PROMPT_COMMAND='history -a;history -c;history -r'
# Put it in your .bashrc file. It ensures each command is immediately saved to
# the .bash_history file, which is how this script will access it.

# I also recommend creating an alias:
# alias log='~/loglast.sh'

if [ $# -lt 2 ]; then
	echo "Usage: $0 <PAA #> <Target IP(s)>"
	exit 1
fi

notes="op_notes_$(date +"%Y%m%d").txt"
if [ ! -f $notes ]; then
    echo DATE: $(date +"%d %b %Y") > ~/$notes
	echo "+----------+-----+------------------------+------------------------------------+" >> ~/$notes
	echo "|   Time   | PAA |      Target IP(s)      | Command                            |" >> ~/$notes
	echo "+----------+-----+------------------------+------------------------------------+" >> ~/$notes
else
	head -n -1 $notes > temp.txt ; mv -f temp.txt $notes
fi

cmd=$(history 1 | sed 's/^ *[^ ]* *//')

printf "| %8s | %2s  | %-22s | %s\n" "$(date +'%T')" "$1" "$2" "$cmd" >> ~/$notes
echo "+----------+-----+------------------------+------------------------------------+" >> ~/$notes
