#!/bin/bash

if [ "$1" == "clean" ]; then
  find data -not -path data -not -path data/BOOTX64.efi -not path data/.gitignore -delete
  echo "Cleaned up the data/ directory!"
  echo "You can now re-run the script with:"
  echo "$0"

  exit 0
fi

#set -x
TAILS_VERSION=$(curl -s http://dl.amnesia.boum.org/tails/stable/ | sed -n "s/^.*\(tails-i386-[0-9.]*\).*$/\1/p")
if [ -z "$TAILS_VERSION" ]; then
  TAILS_VERSION="tails-i386-1.3.2";
  echo "Could not detect latest version. Using $TAILS_VERSION instead."
fi
TAILS_ISO_URL="http://dl.amnesia.boum.org/tails/stable/$TAILS_VERSION/$TAILS_VERSION.iso"
TAILS_SIG_URL="https://tails.boum.org/torrents/files/$TAILS_VERSION.iso.sig"
TAILS_KEY_URL="https://tails.boum.org/tails-signing.key"

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

verify_tails () {
  curl -o data/tails-signing.key $TAILS_KEY_URL
  curl -o data/tails.iso.sig $TAILS_SIG_URL
 
  rm -f data/tmp_keyring.pgp
  gpg --no-default-keyring --keyring data/tmp_keyring.pgp --import data/tails-signing.key

  if gpg --no-default-keyring --keyring data/tmp_keyring.pgp --fingerprint 58ACD84F | grep "A490 D0F4 D311 A415 3E2B  B7CA DBB8 02B2 58AC D84F";then
    echo "The import TAILS developer key is ok."
  else
    echo "ERROR! The imported key does not seem to be right one. Something is fishy!"
    exit 1
  fi
  
  if gpg --no-default-keyring --keyring data/tmp_keyring.pgp --verify data/tails.iso.sig; then
    echo "The .iso seems legit."
  else
    echo "ERROR! The iso does not seem to be signed by the TAILS key. Something is fishy!"
    exit 1
  fi
}

download_tails () {
  curl -k -o data/tails-tmp.iso $TAILS_ISO_URL
  mv data/tails-tmp.iso data/tails.iso
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

  verify_tails

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
  rsync -ah --progress $ISO_PATH/live $DISK_PATH

  echo "All done"
}

create_image;

