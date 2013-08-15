#!/bin/bash

if [ ! -d "data" ]; then
  echo "[+] Creating data/ directory..."
  mkdir data/
fi

create_disk () {
  TARGET_DISK=$1

  # This erases the TARGET disk and creates 1 FAT32 partition that is of the
  # size of the drive.
  if [ "$( uname -s )" == "Darwin" ];then
    diskutil eraseDisk FAT32 TAILSLIVECD $TARGET_DISK
  else
    echo "Currently don't support building image on this platform"
  fi
}

mount_disk () {
  # This mounts the USB disk and returns the mount_point of the USB disk
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
  # This mounts the .iso and returns it's mount point
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
  curl -o data/tails.iso.sig https://tails.boum.org/torrents/files/tails-i386-0.20.iso.sig
  curl -o data/tails.iso http://dl.amnesia.boum.org/tails/stable/tails-i386-0.20/tails-i386-0.20.iso
  curl -o data/tails-signing.key https://tails.boum.org/tails-signing.key

  gpg --no-default-keyring --keyring data/tmp_keyring.pgp --import data/tails-signing.key
  FINGERPRINT=$( gpg --no-default-keyring --keyring data/tmp_keyring.pgp --fingerprint BE2CD9C1 2>/dev/null | awk '/Key fingerprint/ { print $4 $5 $6 $7 $8 $9 $10 $11 $12 $13}')

  if [ "$FINGERPRINT" == "0D24B36AA9A2A651787876451202821CBE2CD9C1" ];then
    echo "ERROR! The imported key does not seem to be right one. Something is fishy!"
    rm data/tmp_keyring.pgp
    exit 1
  fi
  gpg --verify data/tails.iso.sig
}

list_disks () {
  # This lists all the disks in a way that is readable by the user. The read
  # input will then be passed as arugment to the create_disk function.
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
    echo "[+] Generating the BOOTX64.efi with vagrant. This will take a while."
    vagrant up
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
