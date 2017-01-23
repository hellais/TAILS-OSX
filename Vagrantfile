# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
  config.vm.box = "ubuntu/precise32"

  config.vm.synced_folder "data", "/data"

end

$script = <<SCRIPT
cd /data
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y grub-efi-amd64
grub-mkimage -d /usr/lib/grub/x86_64-efi/ -o BOOTX64.efi -O x86_64-efi --prefix /efi/boot part_gpt part_msdos lvm fat ext2 chain boot configfile normal minicmd linux reboot halt search gfxterm gfxmenu efi_gop efi_uga video loadbios gzio video_bochs video_cirrus echo true loadenv

SCRIPT

Vagrant.configure("2") do |config|
    config.vm.provision :shell, :inline => $script
end


