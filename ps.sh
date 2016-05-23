#!/bin/bash
#bgColor=4 #red
#bgColor=1 #blue
if [ $EUID -ne 0 ];then
PS1='$(tput setb 1)$(
    leftPrompt="$USER @ $HOSTNAME" 
    rightLen=$(($(tput cols) - ${#leftPrompt}))
    printf "%s%*s" "$leftPrompt" $rightLen "$(date -R)"
    )$(tput sgr0)\n$(
    maxDirLen=$(($(tput cols)/3))

    if [[ ${PWD} =~ $HOME ]]
    then maxDirLen=$(($maxDirLen + ${#HOME}))
    fi

    if [ $maxDirLen -ge ${#PWD} ]
    then echo "\w"
    else echo ">\W"
    fi
    ) $(tput setb 2)\$$(tput sgr0) '
else
PS1='$(tput setb 4)$(
    leftPrompt="$USER @ $HOSTNAME" 
    rightLen=$(($(tput cols) - ${#leftPrompt}))
    printf "%s%*s" "$leftPrompt" $rightLen "$(date -R)"
    )$(tput sgr0)\n$(
    maxDirLen=$(($(tput cols)/3))

    if [[ ${PWD} =~ $HOME ]]
    then maxDirLen=$(($maxDirLen + ${#HOME}))
    fi

    if [ $maxDirLen -ge ${#PWD} ]
    then echo "\w"
    else echo ">\W"
    fi
    ) $(tput setb 2)\$$(tput sgr0) '
fi







