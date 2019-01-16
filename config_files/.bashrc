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

    alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias lsd="ls -ad */"

#### custom settings
export HISTTIMEFORMAT='%F %T '
export PAGER=less

#### custom aliases
alias dmesg="dmesg --color"
alias bd=". bd -si"
alias vi="nvim"
alias vim="nvim"
alias lx="exa -bghHaliS"

# Only load liquidprompt in interactive shells, not from a script or from scp
echo $- | grep -q i 2>/dev/null && . /usr/share/liquidprompt/liquidprompt

# Custom FireFox profiles
alias firefox_burpsuite="firefox -P 'BurpSuite'"
alias firefox_tor="firefox -P 'Tor'"