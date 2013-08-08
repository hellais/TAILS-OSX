#!/bin/bash

if [ ! -d "data" ]; then
  echo "[+] Creating data/ directory..."
  mkdir data/
fi

create_disk () {
  TARGET_DISK=$1

  if [ "$( uname -s )" == "Darwin" ];then
    diskutil eraseDisk FAT32 TAILSLIVECD $TARGET_DISK
  else
    echo "Currently don't support building image on this platform"
  fi
}

mount_disk () {
  local  __resultvar=$1
  if [ "$( uname -s )" == "Darwin" ];then
    local mount_point="/Volumes/TAILSLIVECD"
    diskutil mount -mountpoint $mount_point TAILSLIVECD
  else
    echo "Currently don't support building image on this platform"
    exit 1
  fi
  eval $__resultvar="'$mount_point'"
}

mount_iso () {
  local  __resultvar=$1
  if [ "$( uname -s )" == "Darwin" ];then
    local mount_point="/Volumes/TAILS_ISO"
    hdiutil attach -mountpoint $mount_point data/tails.iso
  else
    echo "Currently don't support building image on this platform"
    exit 1
  fi
  eval $__resultvar="'$mount_point'"
}

download_tails () {
  curl -o data/tails.iso.sig https://tails.boum.org/torrents/files/tails-i386-0.19.iso.sig
  curl -o data/tails.iso http://dl.amnesia.boum.org/tails/stable/tails-i386-0.19/tails-i386-0.19.iso
  gpg --verify data/tails.sig
}

list_disks () {
  diskutil list
  echo "for example: disk2"
}

create_image () {

  echo "What disk would you like to use for the TAILS image? "
  list_disks 
  read TARGET_DISK

  echo "Warning $TARGET_DISK will be erased. Do you wish to continue [y|n]? "
  read ans 
  
  if [ $ans = y -o $ans = Y -o $ans = yes -o $ans = Yes -o $ans = YES ]
  then
    echo "Ok, you wanted it!"
  else
    echo "Ok, no worries. Still friends, right?"
    exit 1
  fi

  if [ -f data/tails.iso ]; then
    echo "[+] Found tails image in data/tails.iso. Using it!"
  else
    download_tails
  fi

  if [ -f data/BOOTX64.efi ];then
    echo "[+] Found a EFI boot image in data/BOOTX64.efi. Using it."
  else
    echo "[+] We currently don't support generating it. To do so youself you should run:"
    echo "grub2-mkimage -d /usr/lib/grub2-efi/x86_64-efi/ -o BOOTX64.efi -O x86_64-efi --prefix /efi/boot part_gpt part_msdos lvm fat ext2 "
         "chain boot configfile normal minicmd linux reboot halt search"
         "gfxterm gfxmenu efi_gop efi_uga video loadbios gzio video_bochs"
         "video_cirrus echo true loadenv"
    echo "inside of a linux box..."
  fi

  create_disk $TARGET_DISK
  mount_iso ISO_PATH
  mount_disk DISK_PATH

  mkdir -p $DISK_PATH/efi/boot/

  echo "[+] Copying BOOTX64.efi"
  cp data/BOOTX64.efi $DISK_PATH/efi/boot/

  echo "[+] Copying grub.cfg"
  cp grub.cfg $DISK_PATH/efi/boot/

  echo "[+] Copying live directory"
  cp -R $ISO_PATH/live $DISK_PATH/live

  echo "All done"
}

create_image
