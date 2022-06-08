#! /bin/bash

swaymsg 'workspace 8'
swaymsg 'splith'
swaymsg 'layout tabbed'

chromium --incognito 'gmail.com' 'app.slack.com' 'calendar.google.com' &
sleep 2s 
chromium --incognito --new-window 'asana.com' 'notion.com'
