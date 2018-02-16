#!/usr/bin/env bash
# Checks for updates in FreeNAS and sends an email.
# Designed to be run by a cron job

### Variables ###
mailfile="/tmp/update_report.tmp"
email="admin@lamarranet.local"
subject="Updates Check for FreeNAS"
cmd="/usr/local/bin/freenas-update check"

### Set email headers ###
(
    echo "To: ${email}"
    echo "Subject: ${subject}"
    echo "Content-Type: text/html"
    echo "MIME-Version: 1.0"
    echo -e "\r\n"
) > "$mailfile"

### Set email body ###
echo "<pre style=\"font-size:14px\">" >> "$mailfile"

###### summary ######
if "$cmd" >/dev/null 2>&1; then
    echo "Updates available!" >> "$mailfile"
else
    echo "No updates" >> "$mailfile"
fi

echo "</pre>" >> "$mailfile"

### Send report ###
sendmail -t < "$mailfile"
rm "$mailfile"
