#!/bin/bash
#bgColor=4 #red
#bgColor=1 #blue
PS1=$(
if [ $EUID -ne 0 ]; then bgColor='$(tput setb 1)'; 
else bgColor='$(tput set 4)';fi;
clearStyle='$(tput sgr0)'
echo $bgColor'$(
    leftPrompt="$USER @ $HOSTNAME" 
    rightLen=$(($(tput cols) - ${#leftPrompt}))
    printf "%s%*s" "$leftPrompt" $rightLen "$(date -R)"
    )'$clearStyle'\n$(
    maxDirLen=$(($(tput cols)/3))

    if [[ ${PWD} =~ $HOME ]]
    then maxDirLen=$(($maxDirLen + ${#HOME}))
    fi

    if [ $maxDirLen -ge ${#PWD} ]
    then echo "\w"
    else echo ">\W"
    fi
    ) $(tput setb 2)\$'$clearStyle' '
    )







