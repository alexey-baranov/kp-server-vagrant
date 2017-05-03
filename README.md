# Vagrant машина

Запуск
```
vagrant up
```

# Удание
```
vagrant destroy
```

# Доступ внутрь машины
либо
```
vagrant ssh
```
либо
```
vagrant ssh-config
```
и использовать порт и ssh ключ которые выведутся, примерно будет так но зависит от каждого запуска
```
$ vagrant ssh-config
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /Users/lik/Works/ubuntu/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```

Внутри есть пользователь vagrant которому можно sudo без пароля и обычный пользователь ubuntu

Если хост платформа Windows, то рекрмендуется на нее установить https://git-for-windows.github.io/ чтобы был доступен ssh клиент и работал доступ через vagrant ssh

# Настройки сети для vagrant машины

Если хочется чтобы vagrant машина была доступна в локальной сети хостовой машины, нужно применить один из вариантов настройки в Vagrantfile указанных ниже.

Иcточник знаний для детальной конфигурацци https://www.vagrantup.com/docs/networking/public_network.html

## Простой бридж с DHCP
c.vm.network "public_network"

## Бридж со статичным IP, котороый конечно же надо поменять перед vagrant up
c.vm.network "public_network", ip: "192.168.0.17"


# Автоматизированные тесты с помощью testkitchen (https://kitchen.ci/)
Выполнить все тесты и уничтожить vagrant/virtualbox машину если все тесты прошли
```
kitchen test
```

все тесты лежат в папочке ./test и написаны в формате http://serverspec.org/

# Crossbar service and virtualenv
Виртруальное окружение инсталлировано под пользователем ubuntu по пути
```bazaar
/home/ubuntu/venv
```

Чтобы активировать окружение (например установить-обновить python пакеты, либо запустить crossbar вручную)
```bazaar
/home/ubuntu/venv/bin/activate
```
деактивировать
```bazaar
deactivate
```

Crossbar настроен как системный сервис
```bazaar
# service crossbar status
● crossbar.service - Crossbar
   Loaded: loaded (/lib/systemd/system/crossbar.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2017-04-17 09:43:33 UTC; 24min ago
 Main PID: 31658 (crossbar-contro)
    Tasks: 1
   Memory: 54.3M
      CPU: 1.502s
   CGroup: /system.slice/crossbar.service
           └─31658 crossbar-controller                                                                                      

Apr 17 09:43:33 default-bento-ubuntu-1604 systemd[1]: Started Crossbar.
```

Логи crossbar находятся по пути
```bazaar
# ls -al /var/log/crossbar/
total 12
drwxr-xr-x  2 ubuntu ubuntu 4096 Apr 17 09:43 .
drwxrwxr-x 17 root   syslog 4096 Apr 17 09:32 ..
-rw-r--r--  1 ubuntu ubuntu 1627 Apr 17 09:43 node.log
```

Logrotate сервис для crossbar
```bazaar
# cat /etc/logrotate.d/crossbar 

/var/log/crossbar/*.log {
       daily
       rotate 10
       copytruncate
       delaycompress
       compress
       notifempty
       missingok
       create 0640 ubuntu ubuntu
       su ubuntu ubuntu
       sharedscripts
       postrotate
               systemctl restart crossbar >/dev/null 2>&1
       endscript
}
```
