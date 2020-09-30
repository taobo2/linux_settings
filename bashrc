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


