###########
# Aliases #
###########

alias qvirsh='virsh --connect=qemu:///system'
alias journal="pass edit personal/journal/$(date +"%Y-%m-%d")"
alias journaly="pass edit personal/journal/$(date --date='1 year ago' +'%Y-%m-%d')"
alias ssc='pass edit personal/notes/people/ssc'
alias ssh="kitty +kitten ssh"

################
# Theming vars #
################

export FONT='$font'
export BACKGROUND=$relativebackground
export PALLETTE=$pallette

############
# Env vars #
############

export EDITOR='/usr/bin/vim'
export QT_QPA_PLATFORMTHEME='gtk2'
export GTK_THEME='flatcolor'

###############
# Path config #
###############

export PATH="/usr/bin/"
export PATH="$PATH:/usr/sbin/"

export PATH="$PATH:/usr/local/bin/"
export PATH="$PATH:/usr/local/sbin/"

export PATH="$PATH:$HOME/.bin/"
export PATH="$PATH:$HOME/.local/bin/"
