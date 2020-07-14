currentDir(){
    if svn info > /dev/null 2>&1; then
        format $(svn info 2>/dev/null | grep 'Relative URL' | cut -d: -f2)
    else
        echo "${PWD##*/}"
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
  export PS1='\[$(tput bold)$(tput setaf 2)\]\t \u@\h \[$(tput setaf 4)\]$(currentDir) $ \[$(tput sgr0)\]'

fi 
export EDITOR=vim
export TZ=Asia/Shanghai


