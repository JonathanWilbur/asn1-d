# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  # A Debian distro for testing the installation of the Debian package
  config.vm.define "debhost" do |debhost|
    debhost.vm.box = "ubuntu/bionic64"
    debhost.vm.hostname = "debhost"
    debhost.vm.box_check_update = true

    # This only has to be rw so the packages can be put in ./output/packages/deb
    debhost.vm.synced_folder ".", "/vagrant", mount_options: [ "dmode=700", "fmode=400", "rw" ]

    debhost.vm.provision "shell", inline: <<-SHELL
      VERSION=`cat /vagrant/version`
      PACKAGE_NAME="asn1"

      apt-get update -y
      apt-get upgrade -y
      apt --fix-broken install -y
      apt-get install -y libc6-dev gcc

      # Install DMD
      wget -q http://downloads.dlang.org/releases/2018/dmd_2.080.0-0_amd64.deb
      dpkg -i dmd_2.080.0-0_amd64.deb

      # Install GDC and LDC
      apt-get install -y gdc ldc

      # Install Dub
      wget -q https://code.dlang.org/files/dub-1.9.0-linux-x86.tar.gz
      tar -xvzf dub-1.9.0-linux-x86.tar.gz
      mv dub /usr/bin

      # Without rng-tools, generating the GPG key will hang forever on some boxes
      apt-get install -y \
        dpkg-dev \
        lintian \
        dh-make \
        debmake \
        dh-dlang \
        quilt \
        rng-tools \
        dupload

      # Configure swap space
      # Without it, build fails with "out of memory error," even though there is plenty.
      grep -q "swapfile" /etc/fstab
      if [ $? -ne 0 ]; then
        fallocate -l 512M /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
      fi

      # Create a GPG Key. You must have this to create the package.
      gpg --batch --gen-key /vagrant/package/deb/gpg.script

      # Copy over the entire source directory so we don't accidentally screw up the source
      mkdir -p /package/${PACKAGE_NAME}-${VERSION}
      cp -pr /vagrant/* /package/${PACKAGE_NAME}-${VERSION}
      cd /package/${PACKAGE_NAME}-${VERSION}

      # Create the package skeleton
      export DEBEMAIL=jonathan@wilbur.space
      export DEBFULLNAME="Jonathan M. Wilbur"
      dh_make --single --createorig --email jonathan@wilbur.space --copyright=mit --yes

      # Overwrite some of the skeleton files with our own
      #
      # Most files under debian/ MUST be non-executable! If you accidentally
      # make them executable, debuild will execute them, often with anomalous
      # results.
      cp -prv /vagrant/package/deb/debian/* /package/${PACKAGE_NAME}-${VERSION}/debian

      chmod -R +w /package/${PACKAGE_NAME}-${VERSION}

      # This is the only one (I know of) that must be executable
      chmod +x /package/${PACKAGE_NAME}-${VERSION}/debian/rules

      # Everything is owned by root by default, but you ssh in as `vagrant`
      chown -R vagrant:vagrant /package

      # These are just example files generated by dh_make
      rm /package/asn1-${VERSION}/debian/*.ex
      rm /package/asn1-${VERSION}/debian/*.EX

    SHELL
  end

  # An RPM distro for testing the installation of the RPM package
  config.vm.define "rpmhost" do |rpmhost|
    rpmhost.vm.box = "generic/fedora27"
    rpmhost.vm.hostname = "rpmhost"
    rpmhost.vm.synced_folder ".", "/vagrant", mount_options: [ "dmode=700", "fmode=400", "rw" ]
    rpmhost.vm.box_check_update = true
    rpmhost.vm.provision "shell", inline: <<-SHELL
      VERSION=`cat /vagrant/version`
      PACKAGE_NAME="asn1"

      yum upgrade -y

      # Install DMD
      yum install -y glibc-devel.i686 libcurl.i686 # For some reason, you need the 32-bit libs
      wget -q http://downloads.dlang.org/releases/2.x/2.080.0/dmd-2.080.0-0.fedora.x86_64.rpm
      rpm -i dmd-2.080.0-0.fedora.x86_64.rpm

      # Install GDC
      wget -q http://gdcproject.org/downloads/binaries/6.3.0/x86_64-linux-gnu/gdc-6.3.0+2.068.2.tar.xz
      tar -xvf gdc-6.3.0+2.068.2.tar.xz

      # Install LDC
      yum install -y ldc

      # Download Other utilities
      yum install -y \
        nano \
        rpm-build

      # Download the Example RPM
      # Instructions sourced from here: https://access.redhat.com/sites/default/files/attachments/rpm_building_howto.pdf
      wget ftp://ftp.redhat.com/pub/redhat/linux/enterprise/6Workstation/en/os/SRPMS/tree-1.5.3-2.el6.src.rpm
      rpm -i tree-1.5.3-2.el6.src.rpm

      # Create a GPG Key. You must have this to create the package.
      gpg --batch --gen-key /vagrant/package/deb/gpg.script

      # Copy over the entire source directory so we don't accidentally screw up the source
      mkdir -p /package/${PACKAGE_NAME}-${VERSION}
      cp -pr /vagrant/* /package/${PACKAGE_NAME}-${VERSION}
      cd /package/${PACKAGE_NAME}-${VERSION}

      # Build the RPM Package
      cp /vagrant/package/rpm/SPECS/asn1.spec ~/rpmbuild/SPECS
      wget https://github.com/JonathanWilbur/asn1-d/archive/v${VERSION}.tar.gz -O ~/rpmbuild/SOURCES/v${VERSION}.tar.gz

    SHELL
  end

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "1024"
  end

end
