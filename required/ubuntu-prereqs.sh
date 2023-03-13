#!/bin/bash

## script checks minimum tooling required to run install scripts ##
# set -ex

HOST_ARCHITECTURE=''

echo -e '### Starting Pre-requirements checks... ###\n'

# map host arch to common supported nomenclature
if [ $(uname -p) == 'x86_64' ]; then
    HOST_ARCHITECTURE=amd64
elif [ $(uname -p) == 'aarch64' ]; then
    HOST_ARCHITECTURE='arm64'
fi

# check for curl
if [ $(type curl > /dev/null 2>&1; echo $?) != 0 ]
    then
        echo 'curl not found, installing...'
        sudo apt update
        sudo apt upgrade
        sudo apt install -y curl 
        echo "installed curl: $(curl --version | head -n 1)"
    else
        echo "curl install found: $(curl --version | head -n 1)"
fi

# check for wget
if [ $(type wget > /dev/null 2>&1; echo $?) != 0 ]
    then
        echo 'wget not found, installing...'
        sudo apt update
        sudo apt install -y wget
        echo "installed wget: $(wget --version | head -n 1)"
    else
        echo "wget install found: $(wget --version | head -n 1)"
fi


# check for git
if [ $(type git > /dev/null 2>&1; echo $?) != 0 ]
    then
        echo 'git not found, installing...'
        sudo apt update
        sudo apt install -y git
        echo "installed git: $(git --version | head -n 1)"
    else
        echo "git install found: $(git --version | head -n 1)"
fi

# check for yq
if [ $(type yq > /dev/null 2>&1; echo $?) != 0 ]
    then
        echo 'yq not found, installing...'
        wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture) -O /usr/bin/yq && \
            sudo chmod +x /usr/bin/yq
        echo "yq installed: $(yq --version | head -n 1)"
    else
        echo "yq install found: $(yq --version | head -n 1)"
fi

export $HOST_ARCHITECTURE

echo -e '\n### Pre-requirements checks complete... ###'
