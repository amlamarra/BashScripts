#!/usr/bin/env bash
# Takes a file with a list of Python packages.
# Outputs a list of those packages and all necessary dependencies.

infile=packages.txt
outfile=deps.txt

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage:"
    echo "$0 [FILE]    default file name: $infile"
    exit
fi

if ! command -v johnnydep >/dev/null 2>&1; then
    echo "Error: johnnydep is not installed"
    echo '$ sudo pip3 install --user johnnydep'
    exit 1
fi

if [ -n "$1" ]; then
    infile="$1"
fi
if [ ! -f "$infile" ]; then
    echo "Error: $infile not found!"
    exit 1
fi

# Get the total number of packages to check
# Packages can be commented out with a # at the beginning of the line
total=$(sed '/^#/d' "$infile" | wc -l)

# Clean up from previous runs of the script
rm -f "$outfile"

function ProgressBar {
    # Process data
    _progress=$(( $1 * 100 / $2 ))
    _done=$(( _progress * 4 / 10 ))
    _left=$(( 40 - _done ))
    # Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

i=1
# Iterate through each package
while read -r pkg; do
    ProgressBar "$i" "$total"
    # Get dependencies and discard any version information, save to $outfile
    johnnydep -v 0 --output-format pinned "$pkg" | cut -d= -f1 | cut -d\> -f1 | cut -d\< -f1 >> "$outfile"
    i=$((i+1))
done < <(sed '/^#/d' "$infile")

# Sort and uniq the output
sort --ignore-case "$outfile" | uniq > "$outfile.tmp"
mv -f "$outfile.tmp" "$outfile"

echo -e "\nComplete! Output file: $outfile"
