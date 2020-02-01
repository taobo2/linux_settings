export HISTFILESIZE=10000
export HISTIGNORE="rm*:sudo rm*"
export HISTCONTROL="ignorespace"
export PATH=$PATH:./
if [ "$TERM" = "screen" ] || [ ! -z "$VIMRUNTIME" ]; then
  export PS1='\[$(tput setab 6)\]\[$(tput setaf 0)\]\t \h \u \W $ \[$(tput sgr0)\]'
else
  export PS1='\[$(tput setab 3)\]\[$(tput setaf 0)\]\t \h \u \W $ \[$(tput sgr0)\]'
fi
export EDITOR=vim
export TZ=Asia/Shanghai
