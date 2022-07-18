#!/bin/bash
MAX_MEMORY=524288 # in KB
SLACK_HOOK='{{ watchdog_slack_hook }}'

function build_payload {
    echo -n 'payload={"channel": "#notifications", "username": "passenger-killer", "text": "killing passenger pid: ' $1 '", "icon_emoji": ":gun:"}'
}

/usr/sbin/passenger-status --show=xml | \
    xmlstarlet sel -T \
               -t -m '//process' -i "rss > $MAX_MEMORY" -v 'pid' -n | \
    (
        while read workerpid
        do
            if [ $workerpid -eq $workerpid ]; then
                curl --silent -X POST --data-urlencode \
                     "$(build_payload $workerpid)" \
                     "$SLACK_HOOK" > /dev/null
                passenger-config detach-process $workerpid
            fi
        done
    )
