#!/bin/bash

if id -u linuxbrew > /dev/null 2>&1;then
    useradd -m -s /bin/bash linuxbrew
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
fi

su linuxbrew

if [ -n "$_all_proxy" ];then
    all_proxy=$_all_proxy ALL_PROXY=$_all_proxy /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [ -n "$_http_proxy" ] && [ -n "$_https_proxy" ]; then
    http_proxy=$_http_proxy https_proxy=$_https_proxy /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

exit

eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

  





