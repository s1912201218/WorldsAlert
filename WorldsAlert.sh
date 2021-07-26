#!/bin/bash
cd "$(dirname "$0")"

source WorldsAlert.cfg

# Switches

while getopts ":dp" option
do
	case $option in
		p ) echo "Popups enabled."
			popups_enabled="yes";;
		d ) echo "Discord bot enabled."
			discord_enabled="yes";;
		? ) echo "Invalid argument."
			exit;;
	esac
done



# Make temp files

worlds_alert_new=`mktemp`
worlds_alert_old=`mktemp`

trap 'rm -rf -- "$worlds_alert_new" "$worlds_alert_old"' EXIT

rm -f "$worlds_alert_old" "$worlds_alert_new"


Notify()
{


newmessage="`echo "$newmessage" | sed -e 's/\"//g'`"
	if [ "$discord_enabled" == "yes" ]
	then

		# Discord message using curl. Maybe include avatar support later.

		discord_message="{ \"wait\": true, \"content\": \"${newmessage}\", \"username\": \"${discord_username}\" }"
		curl -H "Content-Type: application/json" -H "Expect: application/json" -X POST "${webhook}" -d "${discord_message}" 2>/dev/null
	fi

	if [ "$popups_enabled" == "yes" ]
	then
		xmessage -center "$newmessage" &
	fi

	sleep .1 &
}



while true
do
	if [ ! -f "$logfile" ]
	then
		echo "No log file exists."
		break
	fi

	grep \>\  "$logfile" > "$worlds_alert_new"

	# Watch for incoming messages using md5sum.

	newsum="`md5sum "$worlds_alert_new" | cut -f1 -d' '`"
	oldsum="`md5sum "$worlds_alert_old" 2>/dev/null | cut -f1 -d' '`"

	if [ "$newsum" != "$oldsum" ] && [ -f "$worlds_alert_new" ] && [ -f "$worlds_alert_old" ]
	then
		while read newmessage
		do
			echo "$newmessage"
			Notify
			sleep .5
		done < <(diff "$worlds_alert_new" "$worlds_alert_old" | grep \> | sed -e 's/< //g' | sed -e 's/\r\|\n//g')

	fi
	mv -f "$worlds_alert_new" "$worlds_alert_old"
	sleep 1
done
