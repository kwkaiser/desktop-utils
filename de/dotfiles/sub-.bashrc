###########
# Aliases #
###########

alias sudo='sudo '
alias k='kubectl'
alias docker-rm-all='docker container rm $(docker ps -a -q)'
alias docker-stop-all='docker container stop $(docker ps -a -q)'
alias qvirsh='virsh --connect=qemu:///system'
alias ssh="kitty +kitten ssh"
alias tlmgr="/usr/share/texmf-dist/scripts/texlive/tlmgr.pl"

################
# Theming vars #
################

export FONT='$font'
export BACKGROUND=$relativebackground
export PALETTE=$palette

############
# Env vars #
############

export GTK_THEME='flatcolor'
export EDITOR='vim'
export BROWSER='/usr/bin/firefox'
export QT_QPA_PLATFORM='wayland'
export QT_QPA_PLATFORMTHEME='gtk2'
export XDG_CURRENT_DESKTOP='sway'

###############
# Path config #
###############

export PATH="/usr/bin/"
export PATH="$PATH:/usr/sbin/"

export PATH="$PATH:/usr/bin/core_perl/"


export PATH="$PATH:/usr/local/bin/"
export PATH="$PATH:/usr/local/sbin/"

export PATH="$PATH:$HOME/.bin/"
export PATH="$PATH:$HOME/.local/bin/"
