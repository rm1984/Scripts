# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto -T'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias lsd="ls -ad */"
alias du="du -A"

#### Custom settings
export HISTTIMEFORMAT='%F %T '
export PAGER=less
export QT_QPA_PLATFORMTHEME=gtk2

#### Custom aliases
alias dmesg="dmesg --color"
alias bd=". bd -si"
alias vi="nvim"
alias vim="nvim"
alias lx="exa -bghHaliS"
alias date="date +'%a %d %h %Y %T'"

### Custom FireFox profiles
alias firefox_burpsuite="firefox -P 'BurpSuite'"
alias firefox_tor="firefox -P 'Tor'"

# Custom library paths
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/oracle/instantclient

# Custom binary paths
export GOPATH=~/go
export CARGOPATH=~/.cargo
export ORACLEPATH=$LD_LIBRARY_PATH:/opt/mssql-tools/bin
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:${ORACLEPATH}:${GOPATH}/bin:${CARGOPATH}/bin:

### Only load LiquidPrompt in interactive shells, not from a script or from scp
echo $- | grep -q i 2>/dev/null && . /usr/share/liquidprompt/liquidprompt
