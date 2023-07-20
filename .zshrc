# {{{ linux console

ttyctl -f

bindkey -d

unset HISTFILE
export HISTSIZE=0

[[ $TERM != linux ]] || return 0

# }}}

# {{{ autostart tmux session

if (( $+commands[tmux] && ! $+TMUX && $+SSH_CONNECTION )); then
    tmux has && exec tmux attach
    exec tmux new
fi

# }}}

# {{{ environment variables

typeset -U path cdpath

path+=( ~/bin(N-/) ~/.cargo/bin(N-/) ~/.go/bin(N-/) )

cdpath+=( ~ ~/src(N-/) ~/GitHub(N-/) ~/Projects(N-/) )

# }}}

# {{{ znap

() {
    local znap_home=$HOME/.znap
    [[ -f $znap_home/znap.zsh ]] \
        || git clone --depth=1 https://github.com/marlonrichert/zsh-snap.git $znap_home

    . $znap_home/znap.zsh

    zstyle ':znap:*' repos-dir $znap_home/repos
}

# }}}

# {{{ zsh-users

znap source zsh-users/zaw
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-completions
znap source zsh-users/zsh-syntax-highlighting

# }}}

# {{{ prezto

znap source sorin-ionescu/prezto modules/{command-not-found,completion}

# }}}

# {{{ prompt

export PURE_PROMPT_SYMBOL='›'
export PURE_PROMPT_VICMD_SYMBOL='‹'

# znap source kur-11/pure async.zsh pure.zsh
. ~/GitHub/pure/async.zsh
. ~/GitHub/pure/pure.zsh

# }}}

# {{{ ostype

is_linux=0 is_osx=0

case $OSTYPE in
    linux*)  is_linux=1 ;;
    darwin*) is_osx=1 ;;
esac

# }}}

# {{{ dotfiles

() {
    local gitdir=$HOME/GitHub/dotfiles worktree=$HOME

    alias dotfiles="git --git-dir=$gitdir --work-tree=$worktree"
    compdef dotfiles=git

    eval "$(dotfiles rev-parse --is-inside-work-tree 2>/dev/null || echo false)" \
        || git init --bare $gitdir
}

# }}}

autoload -Uz add-zsh-hook

# {{{ history

setopt BANG_HIST
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt SHARE_HISTORY

HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=$((HISTSIZE * 365))

typeset -TUx HISTORY_IGNORE history_ignore '|'
history_ignore+=('history' 'history *')

my_zshaddhistory() {
    local r="($HISTORY_IGNORE)"
    [[ $1 != ${~r} ]]
}

add-zsh-hook zshaddhistory my_zshaddhistory

alias history='fc -lDi'

bindkey '' history-beginning-search-backward
bindkey '' history-beginning-search-forward

# }}}

# {{{

autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars ' _-./:;@?='
zstyle ':zle:*' word-style unspecified

# }}}

# {{{

clear_screen_and_scrollback() {
    echoti civis >"$TTY"
    printf '%b' '\e[H\e[2J' >"$TTY"
    zle .reset-prompt
    zle -R
    printf '%b' '\e[3J' >"$TTY"
    echoti cnorm >"$TTY"
}

zle -N clear_screen_and_scrollback
bindkey '' clear_screen_and_scrollback

# }}}

# {{{

autoload smart-insert-last-word
zle -N insert-last-word smart-insert-last-word

# }}}

# {{{ automatic escaaping when pasting

autoload -Uz bracketed-paste-url-magic
zle -N bracketed-paste bracketed-paste-url-magic

# }}}

# {{{ aliases

alias relogin='exec $SHELL -l'

# }}}

# {{{ functions

ipv4() { curl -fsS https://api.ipify.org; echo }
ipv6() { curl -fsS https://api64.ipify.org; echo }
mkcd() { install -Ddv "$1" && cd "$1" }

urlencode() {
    if [[ "$1" == '-d' ]]; then
        cat | sed 's/+/ /g; s/\%/\\x/g' | xargs -rd\\n printf '%b\n'
    else
        local c
        cat | fold -b1 - | while read -r c; do
            case $c in
                [a-zA-Z0-9.~_-]) printf '%c' "$c" ;;
                ' ') printf + ;;
                *) printf '%%%.2X' "'$c" ;;
            esac
        done
        echo
    fi
}

wq() {
    local -A opthash

    zparseopts -D -A opthash -- s: t: p: W w o:

    local s
    if (( $+opthash[-s] )); then
        s="$opthash[-s]"
    fi
    [[ -z "$s" ]] && return 10

    local t=WPA
    if (( $+opthash[-t] )); then
        t="$opthash[-t]"
    fi
    [[ "$t" != WPA && "$t" != WEP ]] && return 11

    if (( $+opthash[-W] )); then
        t=WPA
    fi

    if (( $+opthash[-w] )); then
        t=WEP
    fi

    if (( $+opthash[-p] )); then
        p="$opthash[-p]"
        [[ "$p" == - ]] && read -s p
    fi

    local opt=(-lH)
    if (( $+opthash[-o] )); then
        opt+=(-o"$opthash[-o]")
    else
        opt+=(-tANSI)
    fi

    qrencode "$opt[@]"  "WIFI:S:$s;T:$t;P:$p;;"
}

# }}}

# {{{ emacs

if (( $+commands[emacsclient] )); then
    alias emacs='emacsclient -t'
fi

# }}}

# {{{ coreutils

alias ls='ls -Xv --color=auto --group-directories-first'

# }}}

# {{{ grep

alias grep='grep --color=auto'

# }}}

# {{{ go

export GOPATH=$HOME/.go

# }}}

# {{{ zcompile and load .local

setopt NULL_GLOB
setopt EXTENDED_GLOB

zcompile-if-needed() {
    local src=$1 zwc=$1.zwc
    if [[ ! -f $zwc || $src -nt $zwc ]]; then
        zcompile $src
    fi
}

zcompile-if-needed ~/.zshrc

() {
    while (( $# )); do
        zcompile-if-needed $1
        . $1
        shift
    done
} ~/.zshrc.*~*.zwc~*\~

# }}}
