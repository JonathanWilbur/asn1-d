# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  # A Debian distro for testing the installation of the Debian package
  config.vm.define "debhost" do |debhost|
    debhost.vm.box = "ubuntu/bionic64"
    debhost.vm.synced_folder "./build/packaging/deb", "/vagrant/deb"
    debhost.vm.box_check_update = true
    debhost.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get upgrade
      apt-get install -y dpkg-dev lintian dh-make debmake dh-dlang
      sudo wget http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
      sudo apt-get update && sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring
      sudo apt-get update && sudo apt-get install dmd-compiler dub
    SHELL
  end

  # An RPM distro for testing the installation of the RPM package
  config.vm.define "rpmhost" do |rpmhost|
    rpmhost.vm.box = "generic/fedora27"
    rpmhost.vm.synced_folder "./build/packaging/rpm", "/vagrant/rpm"
    rpmhost.vm.box_check_update = true
    rpmhost.vm.provision "shell", inline: <<-SHELL
      yum upgrade
      curl -fsS https://dlang.org/install.sh | bash -s dmd
    SHELL
  end

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "512"
  end

end
