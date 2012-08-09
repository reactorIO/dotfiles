#!/bin/bash

shopt -s dotglob nullglob globstar

updateDotfiles() {
    type -p git >/dev/null 2>&1 || return 1
    rm -rf /tmp/cdown-dotfiles
    git clone git://github.com/cdown/dotfiles.git /tmp/cdown-dotfiles || return 2
    for file in ~/git/dotfiles/**/*; do
        fileName=${file##~/git/dotfiles/}
        [[ ! -f $file ]] && continue
        [[ $fileName == .git/* || $fileName == .gitignore ]] && continue
        [[ -e ~/$fileName ]] && unlink ~/"$fileName"
    done
    mkdir -p ~/git
    rm -rf ~/git/dotfiles && mv /tmp/cdown-dotfiles ~/git/dotfiles || return 3
    for file in ~/git/dotfiles/**/*; do
        fileName=${file##~/git/dotfiles/}
        dirName=~/${fileName%/*}
        [[ ! -f $file ]] && continue
        [[ $fileName == .git/* || $fileName == .gitignore ]] && continue
        [[ $fileName == */* ]] && mkdir -p "${fileName%/*}" 
        [[ -e ~/$fileName ]] && unlink ~/"$fileName"
        if [[ $dirName != "$fileName" ]]; then
            [[ -d $dirName ]] || mkdir -p "$dirName"
        fi
        ln -s "$file" ~/"$fileName"
    done
    [[ -r ~/.bash_profile ]] && . ~/.bash_profile noupdate
}

getTerminfo() {
    if [[ $TERM == st || $TERM == st-256color ]]; then
        if [[ ! -f ~/.terminfo/s/st || ! -f ~/.terminfo/s/st-256color ]]; then
            wget -qO /tmp/st.info http://sprunge.us/BNMe && tic /tmp/st.info
            rm /tmp/st.info
        fi
    fi
}

getLocale() {
    localesDesired=({en_{GB,US},C}.{utf8,UTF-8}) 
    unset LANG
    while IFS= read -r localeAvailable; do
        localesAvailable+=( "$localeAvailable" )
    done < <(locale -a)
    for localeDesired in "${localesDesired[@]}"; do
        for localeAvailable in "${localesAvailable[@]}"; do
            if [[ $localeAvailable == "$localeDesired" ]]; then
                LANG=$localeAvailable
                break 2
            fi
        done
    done
    : ${LANG:=C}
}

runSSHAgent() {
    if pgrep -u "$EUID" -x ssh-agent && [[ -f ~/.ssh-agent ]]; then
        . ~/.ssh-agent
    else
        ssh-agent > ~/.ssh-agent
        . ~/.ssh-agent
        ssh-add
    fi
}

exportEnvironment() {
    export EDITOR=vim
    export LANG
    export LESS="-X -S"
    export LESSSECURE=1
    export PAGER=less
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
}

if [[ $1 == noupdate ]]; then
    [[ -r ~/.bashrc ]] && . ~/.bashrc
    getTerminfo
    getLocale
    exportEnvironment
else
    if ! [[ $SSH_CLIENT ]] && (( EUID )); then
        runSSHAgent
    fi
    updateDotfiles
fi
