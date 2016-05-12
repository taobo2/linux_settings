#!/bin/sh

function fail(){
    echo 'Fail to recover. Exit.' 1>&2
    exit 1
}

function recoverFile(){
    file=$1
    if [ ! -e $file ]
    then echo "Backup file $file doesn't exist. Ignore it."
    else
        target="$HOME/$(basename $file)"
        rm -f $target
        mv $file $target || fail
    fi
}

function recover(){
    recoverFile "$backupDir/.vimrc"
    recoverFile "$backupDir/.bashrc"
}


backupDir="$HOME/.linux_settings_backup"
if [ -d $backupDir ]
then 
    recover 
else 
    echo "$backupDir doesn't exist. Stop backup."
fi

