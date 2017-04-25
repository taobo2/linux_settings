#!/bin/bash
config_file='/etc/ssh/sshd_config'
backup_file=$config_file'.bak'

if [ -f $backup_file ]; then
    echo '$backup_file found, recover'
    mv -f $backup_file $config_file
else
    echo '$backup_file not found'
fi

if [[ $1 == '-u' ]] 
then
    exit 0
else
    echo 'add settings to $config_file'
    cp -f $config_file $backup_file
    echo 'ClientAliveInterval 120' >> $config_file
    echo 'ClientAliveCountMax 720' >> $config_file
    echo 'AllowAgentForwarding yes' >> $config_file
fi
  
service sshd restart 
