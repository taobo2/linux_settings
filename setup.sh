#!/bin/bash

function checkComResult(){
    command=$1
    if [ $? -eq 0 ]
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
    sed -i "/$startLine/, /$endLine/d" $bashrc
    checkComResult 'Recover .bashrc'
    rm -f ~/.vimrc 
    mv $setDir/.vimrc ~/.vimrc
    checkComResult 'Recover .vimrc'
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
    if [ $run != 'y' ] 
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
cp -f $scriptDir/vimrc $HOME/.vimrc 
checkComResult 'Set .vimrc'

cp -f $scriptDir/ps.sh $setDir/ps.sh

echo $startLine >> $bashrc
echo "HISTFILESIZE=10000" >> $bashrc
echo "source $setDir/ps.sh" >> $bashrc
echo $endLine >> $bashrc
checkComResult 'Set .bashrc'

