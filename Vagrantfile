Vagrant.configure("2") do |c|
  c.berkshelf.enabled = false if Vagrant.has_plugin?("vagrant-berkshelf")
  c.vm.box = "ubuntu/xenial64"
  c.vm.hostname = "ubuntu1604.vagrant.com"
  c.vm.synced_folder ".", "/vagrant", disabled: true
  c.vm.boot_timeout = 300

  c.vm.provision "shell" do |s|
    # Скрипт настройки
    s.path = 'bootstrap.sh'
    #s.inline =''
  end

  c.vm.provider "virtualbox" do |v|
    # Если нужно получить локальную консоль
    v.gui = true

    # Память и процессоры
    v.memory = 1024
    v.cpus = 2
  end

  # Монтирование локальной папки с проектом внутрь виртуальной машины
  #c.vm.synced_folder ".", "/home/ubuntu/htdocs", owner: "ubuntu", group: "ubuntu", create: true

  # Иcточник знаний для детальной конфигурацци https://www.vagrantup.com/docs/networking/public_network.html
  # Простой бридж с DHCP
  # c.vm.network "public_network"

  # Бридж со статичным IP, который конечно же надо поменять перед vagrant up
  # c.vm.network "public_network", ip: "192.168.0.17"

  # Маппинг портов для доступа к приложу и к базе с хостовой системы
  # http://localhost:8080
  c.vm.network "forwarded_port", guest: 80, host: 8080
  c.vm.network "forwarded_port", guest: 443, host: 8443
  # psql -h localhost -p 15432
  c.vm.network "forwarded_port", guest: 5432, host: 15432
end
