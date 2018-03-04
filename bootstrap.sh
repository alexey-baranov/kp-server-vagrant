#!/bin/bash

# Configure locales
echo locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8 | debconf-set-selections
echo locales locales/default_environment_locale select  en_US.UTF-8 | debconf-set-selections
dpkg-reconfigure locales -f noninteractive
echo -e 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8' > /etc/default/locale

# Prepare OS
sudo sed -i 's/archive.ubuntu.com/mirror.yandex.ru/g' /etc/apt/sources.list

su - root -c 'apt-get update'

# User ubuntu, creates only if virtual environment, in production should be created at Ubuntu installation step
id ubuntu > /dev/null 2>&1 || ( adduser --disabled-password --gecos "" ubuntu && echo ubuntu:qwerty | chpasswd )

# NTP
su - root -c 'apt-get install ntp -y'

# Common packages
su - root -c 'apt-get install mc unrar -y'

# NVM
su - ubuntu -c 'wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash'
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install v7.7.2'

# xfce
su - root -c 'apt-get install -y xfce4 lightdm'

# SFTP
su - root -c 'apt-get install mysecureshell -y'

#vagrant
su - root -c 'apt-get install docker'