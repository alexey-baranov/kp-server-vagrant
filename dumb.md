#Раздел для тех у кого нет памяти ))

#host
10.1.10.148
root:secret


добавить пользователя ubuntu
```
adduser --disabled-password --gecos "" ubuntu && echo ubuntu:Jachgib4 | chpasswd
```

сменить пароль
```
sudo passwd ubuntu
```

добавить в sudo
```
sudo useradd ubuntu sudo
```

vbox guest addition
```
sudo apt-get install virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms
```
https://askubuntu.com/questions/22743/how-do-i-install-guest-additions-in-a-virtualbox-vm