# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  # A Debian distro for testing the installation of the Debian package
  config.vm.define "debhost" do |debhost|
    debhost.vm.box = "ubuntu/bionic64"
    debhost.vm.synced_folder "./build/packaging/deb", "/vagrant"
    debhost.vm.box_check_update = true

    # TODO: Make and test with $VERSION variable
    debhost.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get upgrade

      # Without rng-tools, generating the GPG key will hang forever on some boxes
      apt-get install -y \
        dpkg-dev \
        lintian \
        dh-make \
        debmake \
        dh-dlang \
        quilt \
        rng-tools

      # Install D
      sudo wget http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
      sudo apt-get update && sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring
      sudo apt-get update && sudo apt-get install dmd-compiler dub

      # Configure swap space
      # Without it, build fails with "out of memory error," even though there is plenty.
      swapsize=512 # size of swapfile in megabytes
      grep -q "swapfile" /etc/fstab # does the swap file already exist?
      if [ $? -ne 0 ]; then # if not then create it
        fallocate -l ${swapsize}M /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
      fi

      # Create GPG Key
      gpg --batch --gen-key /vagrant/gpg.script

      # Create the packaging directory and configuration files
      mkdir /package
      cd /package
      git clone https://github.com/JonathanWilbur/asn1-d.git
      mv asn1-d asn1-2.4.1
      cd asn1-2.4.1/
      export DEBEMAIL=jonathan@wilbur.space
      export DEBFULLNAME="Jonathan M. Wilbur"
      dh_make --single --createorig
      cp /vagrant/debian/* /package/asn1-2.4.1/debian
      rm /package/asn1-2.4.1/debian/*.ex
      rm /package/asn1-2.4.1/debian/*.EX

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
    vb.memory = "1024"
  end

end
