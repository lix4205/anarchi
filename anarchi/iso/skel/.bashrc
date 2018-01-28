#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

PS1="[\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]]\\$ \[\033[s\]\[\033[1;\$((COLUMNS-COL_TOCHANGE))f\]TEXT_TOCHANGE\[\033[u\]" 