#! /bin/bash

swaymsg 'workspace 10'

swaymsg 'splith'
spotify & sleep 1s


pavucontrol &  sleep 1s
# 
swaymsg 'splitv'

blueman-manager 
