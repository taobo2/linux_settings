#!/bin/bash

function checkComResult(){
    command=$1
    result=$2
    if [ $result -eq 0 ]
    then
        echo $command 'succeed.'
    else
        echo $command 'failed.' 1>&2
        exit 1
    fi
}

startLine="#====================Add by Bob Linux Setting====================" 
endLine="#================================================================" 
setDir=~/.bob_linux_settings
bashrc=~/.bashrc

function unsetup(){
    if [ "$(uname)" == "Darwin" ]; then
        sed -i ''  "/$startLine/, /$endLine/d" $bashrc
    else
        sed -i "/$startLine/, /$endLine/d" $bashrc
    fi
    checkComResult 'Recover .bashrc' $? #pass $? as parameter, since call function(function is a command itself)  may reset $?

    if [ -e $setDir/.vimrc ]; then
        rm -f ~/.vimrc 
        mv $setDir/.vimrc ~/.vimrc
        checkComResult 'Recover .vimrc' $?
    fi
    rm -rf $setDir
}

if [ "$1" = '-r' ]
then 
    unsetup
    exit 0
fi


if [  -d $setDir ]
then 
    echo -e 'It seems that the setup has been run.\n'
    read -p 'Do you want to rerun it?(y/n)' run
    if [ -z $run ] || ([ $run != 'yes' ] && [ $run != 'y' ])
    then exit 0
    fi
    unsetup   
fi

mkdir $setDir || { echo "Fail to create backup dir $setDir." 1>&2; exit 1; }

function backup(){
    local file=$1

    if [ ! -e $file ]
    then return
    fi

    local backup="$setDir/"$(basename $file)
    rm -f $backup
    local command=$2
    $2 $file $backup || { echo "Fail to backup $file." 1>&2; exit 1 ;}
}

scriptDir=$(cd $(dirname "$BASH_SOURCE[0]") && pwd -P && cd - > /dev/null)

vimrc="$HOME/.vimrc" 
backup $vimrc mv
cp  $scriptDir/vimrc $HOME/.vimrc 
checkComResult 'Set .vimrc' $?

cp -f $scriptDir/ps.sh $setDir/ps.sh

echo $startLine >> $bashrc
echo "export HISTFILESIZE=10000" >> $bashrc
echo 'export HISTIGNORE="rm*:sudo rm*"' >> $bashrc
echo 'export HISTCONTROL="ignorespace"' >> $bashrc
echo "source $setDir/ps.sh" >> $bashrc
echo $endLine >> $bashrc
checkComResult 'Set .bashrc' $?

