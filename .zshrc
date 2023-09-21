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

typeset -U path cdpath fpath

() {
    local path_helper=/usr/libexec/path_helper
    [[ -x $path_helper ]] && eval "$($path_helper)"
    (( $+commands[brew] )) && path=( $(brew --prefix coreutils 2>/dev/null)/libexec/gnubin(N-/) $path )
}

path=( ~/bin(N-/) ~/.cargo/bin(N-/) ~/.go/bin(N-/) $path )

cdpath=( ~ ~/src(N-/) ~/GitHub(N-/) ~/Projects(N-/) $cdpath )

fpath=( /usr/local/share/zsh/site-functions(N-/) $fpath )

# }}}

# {{{ znap

() {
    local znap_home=$HOME/.znap
    [[ -f $znap_home/znap.zsh ]] \
        || git clone --depth=1 https://github.com/marlonrichert/zsh-snap.git $znap_home

    . $znap_home/znap.zsh

    zstyle ':znap:*' repos-dir $znap_home/repos
}

znapcomp() {
    znap function {_,}$1 "$2"
    compctl {_,}$1
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

# {{{ asdf

znap source asdf-vm/asdf asdf.sh

() {
    local v
    zstyle -g v ':znap:*' repos-dir
    fpath+=($v/asdf-vm/asdf/completions(N-/))
}

() {
    local rc=$HOME/.config/asdf-direnv/zshrc
    [[ ! -f $rc ]] && asdf direnv setup --shell zsh --version latest
    . $rc
}

# }}}

# {{{ prompt

export PURE_PROMPT_SYMBOL='›'
export PURE_PROMPT_VICMD_SYMBOL='‹'

znap source kur-11/pure async.zsh pure.zsh

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
    (( $+opthash[-s] )) && s="$opthash[-s]"
    [[ -z "$s" ]] && return 10

    local t=WPA
    (( $+opthash[-t] )) && t="$opthash[-t]"
    [[ "$t" != WPA && "$t" != WEP ]] && return 11

    (( $+opthash[-W] )) && t=WPA
    (( $+opthash[-w] )) && t=WEP
    if (( $+opthash[-p] )); then
        p="$opthash[-p]"
        [[ "$p" == - ]] && read -s p
    fi

    local opt=(-lH)
    (( $+opthash[-o] )) \
        && opt+=(-o"$opthash[-o]") \
        || opt+=(-tANSI)

    qrencode "$opt[@]"  "WIFI:S:$s;T:$t;P:$p;;"
}

yt-feed() {
    curl -fsS "$1" | pup 'link[rel="canonical"] attr{href}' \
        | sed -e 's/^.*\/\([^/]*\)$/\1/' | xargs -r printf 'https://www.youtube.com/feeds/videos.xml?channel_id=%s\n'
}

# }}}

# {{{ emcs

if (( $+commands[emacsclient] )); then
    alias emacs='emacsclient -t'
fi

# }}}

# {{{ coreutils

alias ls="ls -Xv --color=auto --group-directories-first"

# }}}

# {{{ grep

alias grep="grep --color=auto"

# }}}

# {{{ go

export GOPATH=$HOME/.go

# }}}

# {{{

# }}}

# {{{ ssh-agent

pgrep -u "$USR" ssh-agent > /dev/null \
    || eval "$(ssh-agent)" > /dev/null

# }}}

# {{{

if (( $+commands[trivy] )); then
    znapcomp trivy 'eval "$(trivy completion zsh)"'
fi

if (( $+commands[grype] )); then
    znapcomp grype 'eval "$(grype completion zsh)"'
fi

if (( $+commands[syft] )); then
    znapcomp syft 'eval "$(syft completion zsh)"'
fi

if (( $+commands[gibo] )); then
    znapcomp gibo 'eval "$(gibo completion zsh)"'
fi

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



# {{{ yubikey

path+=(/Applications/YubiKey\ Manager.app/Contents/MacOS(N-/))

# }}}
