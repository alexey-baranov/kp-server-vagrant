Vagrant.configure("2") do |c|
  c.berkshelf.enabled = false if Vagrant.has_plugin?("vagrant-berkshelf")
  c.vm.box = "bento/ubuntu-16.04"
  c.vm.hostname = "default-bento-ubuntu-1604.vagrantup.com"
  c.vm.synced_folder ".", "/vagrant", disabled: true

  c.vm.provider :digital_ocean do |p, override|
    override.ssh.private_key_path = '~/.ssh/id_rsa'
    p.ssh_key_name = 'sergey-korolev-pub'
    p.token = ENV['DIGITALOCEAN_ACCESS_TOKEN']
    p.image = 'ubuntu-16-04-x64'
    p.size = '2gb'
  end

  c.vm.provision "shell" do |s|
    # Скрипт настройки
    s.path = 'bootstrap.sh'
  end

  c.vm.provider "virtualbox" do |v|
    # Если нужно получить локальную консоль
    # v.gui = true

    # Память и процессоры
    v.memory = 2048
    v.cpus = 2
  end

  # Монтирование локальной папки с проектом внутрь виртуальной машины
  #c.vm.synced_folder ".", "/home/ubuntu/htdocs", owner: "ubuntu", group: "ubuntu", create: true

  # TODO: add network configuration host/bridge/static/dhcp options
  # Маппинг портов для доступа к приложу и к базе с хостовой системы
  # http://localhost:8080
  c.vm.network "forwarded_port", guest: 80, host: 8080
  c.vm.network "forwarded_port", guest: 443, host: 8443
  # psql -h localhost -p 15432
  c.vm.network "forwarded_port", guest: 5432, host: 15432
end
