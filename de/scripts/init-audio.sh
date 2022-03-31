#! /bin/bash

swaymsg 'workspace 10'

swaymsg 'splitv'
spotify & sleep 1s


pavucontrol &  sleep 1s
# 
swaymsg 'splith'

blueman-manager &

swaymsg 'layout tabbed'