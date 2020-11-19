currentDir(){
    if svn info > /dev/null 2>&1; then
        echo $(svn info 2>/dev/null | grep 'Relative URL' | cut -d: -f2)
    elif git branch --show-current > /dev/null 2>&1; then
        if [ $(git rev-parse --show-toplevel) == ${PWD} ]; then
            echo $(git rev-parse --show-toplevel | xargs basename):$(git branch --show-current)
        else
            echo $(git rev-parse --show-toplevel | xargs basename):$(git branch --show-current):$(basename $PWD)
        fi
    else
        echo "$1"
    fi
}

format(){
    shrink ${1%/*} ${1##*/}
}

shrink(){ 
    if [ ${#1} -lt $(($(tput cols)/3)) ]; then
        echo $1":"$2
    else
        shrink ${1%/*} $2
    fi
}

export HISTFILESIZE=10000
export HISTIGNORE="rm*:sudo rm*"
export HISTCONTROL="ignorespace"
export PATH=$PATH:./

if [[ "$TERM" = *"screen"* ]] || [ ! -z "$VIMRUNTIME" ]; then
    export PS1='\[$(tput setab 6)\]\[$(tput setaf 0)\]\t \u@\h \W $ \[$(tput sgr0)\]'
else
    export PS1='\[$(tput bold)$(tput setaf 2)\]\t \u@\h \[$(tput setaf 4)\]$(currentDir '"'\w'"') \[$(tput sgr0)\]\n$ '
fi 
export EDITOR=vim
export TZ=Asia/Shanghai

sudo() {
    if [ "apt" == "$1" ] || [ "apt-get" == "$1" ];then
        command sudo http_proxy="$_http_proxy" https_proxy="$_https_proxy" "$@"
    else
        command sudo "$@"
    fi
}

git() {
    proxyOps="clone pull push"
    if ! [[ "$proxyOps" =~ "$1" ]];then
        command git "$@"
        return
    fi
    
    if [ -n "$_all_proxy" ];then
        all_proxy="$_all_proxy" command git "$@"
    else
        http_proxy="$_http_proxy" https_proxy="$_https_proxy" command git "$@"
    fi
}

brew() {
    if [ -n "$_all_proxy" ];then
        all_proxy="$_all_proxy" command brew "$@"
    else
        http_proxy="$_http_proxy" https_proxy="$_https_proxy" command brew "$@"
    fi
}

npm() {
    http_proxy="$_http_proxy" https_proxy="$_https_proxy" command npm "$@"
}

alias mysql="rlwrap mysql"

alias jdb="rlwrap jdb"

if [ -f ~/.*.bashrc ]; then
    for f in ~/.*.bashrc; do source $f; done
fi

