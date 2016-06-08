#!/bin/bash
#bgColor=4 #blue
#bgColor=1 #red
PS1=$(
if [ $EUID -ne 0 ]; then bgColor='\[$(tput setab 4)\]'; 
else bgColor='\[$(tput setab 1)\]';fi; #\[ \] to make command line wrap normally

clearStyle='\[$(tput sgr0)\]'
echo $bgColor'\[$(tput setaf 7)\[$(
    leftPrompt="$USER @ $HOSTNAME" 
    rightLen=$(($(tput cols) - ${#leftPrompt}))
    printf "%s%*s" "$leftPrompt" $rightLen "$(date +%Y-%m-%d\ %H:%M:%S\ %z)"
    )'$clearStyle'\n$(
    maxDirLen=$(($(tput cols)/3))

    if [[ ${PWD} =~ $HOME ]]
    then maxDirLen=$(($maxDirLen + ${#HOME}))
    fi

    if [ $maxDirLen -ge ${#PWD} ]
    then echo "\w"
    else echo ">\W"
    fi
    ) \[$(tput setab 0)\]\[$(tput setaf 2)\]\$'$clearStyle' '
    )







