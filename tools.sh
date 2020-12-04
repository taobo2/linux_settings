#!/bin/bash
apt-get update && apt-get install -y \
    vim \
    git \
    nodejs \
    npm \
    bsdmainutils \
    locales \
    curl \
    file \
    tzdata \
    screen \
    universal-ctags \
    build-essential \
    openssh-client

npm install -g jshint

locale-gen en_US.UTF-8

