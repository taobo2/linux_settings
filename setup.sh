#!/bin/bash

backupDir=~/.linux_settings_backup
if [  -d $backupDir ]
then 
    echo -e 'It seems that the setup has been run.\n'
    read -p 'Do you want to rerun it?(y/n)' run
    if [ $run != 'y' ] 
    then exit 0
    fi
    
    read -p 'The previous backup files will be removed. Are you sure?(Y/n)' run
    if [ $run != 'Y' ]
    then exit 0
    fi
else
    mkdir $backupDir || { echo "Fail to create backup dir $backupDir." 1>&2; exit 1; }
fi

scriptDir=$(dirname "$(readlink -f "$0")")

function backup(){
    local file=$1

    if [ ! -e $file ]
    then return
    fi

    local backup="$backupDir/"$(basename $file)
    rm -f $backup
    local command=$2
    $2 $file $backup || { echo "Fail to backup $file." 1>&2; exit 1 ;}
}

vimrc="$HOME/.vimrc" 
backup $vimrc mv
ln -s "$scriptDir/vimrc" ~/.vimrc

bashrc="$HOME/.bashrc" 
backup $bashrc cp
echo "====================Add by Bob Linux Setting====================" >> $bashrc
echo "HISTFILESIZE=10000" >> $bashrc
echo "================================================================" >> $bashrc

