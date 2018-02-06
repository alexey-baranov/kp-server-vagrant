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