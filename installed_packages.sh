#!/usr/bin/env bash
# Display all installed packages as well as their size in descending order (by size)

dpkg-query -W --showformat='${Installed-Size;10}\t${Package}\n' | sort -k1,1n
