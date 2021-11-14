###########
# Aliases #
###########

alias qvirsh='virsh --connect=qemu:///system'
alias journal="pass edit personal/journal/$(date +"%Y-%m-%d")"
alias ssc='pass edit personal/notes/people/ssc'
alias pomo="sleep 10s && notify-send -u critical 'POMO'"

############
# Env vars #
############

export EDITOR="/usr/bin/vim"

###############
# Path config #
###############

export PATH="/usr/bin/"
export PATH="$PATH:/usr/sbin/"

export PATH="$PATH:/usr/local/bin/"
export PATH="$PATH:/usr/local/sbin/"

export PATH="$PATH:$HOME/.bin/"
export PATH="$PATH:$HOME/.local/bin/"
