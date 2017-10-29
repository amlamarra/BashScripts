#!/bin/bash -i

# loglast.sh
# This script will log the last saved command from the .bash_history file.
# Author: Lt Andrew Lamarra
# Date created: 28 OCTOBER 2017

# This needs to be executed before anything else:
# export PROMPT_COMMAND='history -a;history -c;history -r'
# Put it in your .bashrc file. It ensures each command is immediately saved to
# the .bash_history file, which is how this script will access it.

if [ $# -lt 2 ]; then
    echo "Usage: $0 <PAA #> <Remote IP>"
    exit 1
fi

notes="operator_notes.txt"
if [ ! -f $notes ]; then
    echo "+-------------------+-----+-----------------------" >> ~/$notes
    echo "|    Date & Time    | PAA | Command" >> ~/$notes
    echo "+-------------------+-----+-----------------------" >> ~/$notes
fi

cmd=$(history 1 | sed 's/^ *[^ ]* *//')

printf "| %+17s | %+2s  | %s\n" "$(date +'%D %T')" "$1" "$cmd" >> ~/$notes
