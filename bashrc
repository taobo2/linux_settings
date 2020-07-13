currentDir(){
    if svn info > /dev/null 2>&1; then
        echo $(svn info 2>/dev/null | grep 'Relative URL' | cut -d: -f2)
    else
        echo "${PWD##*/}"
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


