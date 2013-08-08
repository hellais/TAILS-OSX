
# How to create a TAILS image for OSX

Following this guide you will be able to create a TAILS image that will work on
OSX without requiring any REFIT or bootloader modifications to the target
system.


We assume you are running on Mac OS X and have basic developer tools installed
(ex. git).


```
git clone https://github.com/hellais/TAILS-OSX.git
cd TAILS-OSX
```

## Create the EFI bootloader

You can either build the EFI bootloader containing grub yourself from a linux
machine by running this command:

```
grub2-mkimage -d /usr/lib/grub2-efi/x86_64-efi/ -o BOOTX64.efi \
-O x86_64-efi --prefix /efi/boot part_gpt part_msdos lvm fat ext2 \
chain boot configfile normal minicmd linux reboot halt search \
gfxterm gfxmenu efi_gop efi_uga video loadbios gzio video_bochs \
video_cirrus echo true loadenv
```

Or if you are lazy and don't care about security you can trust that this
sketchoid ran the above command and saved the file to this address:
https://sites.google.com/a/montleon.com/home/EFI.tar.gz.

Use at your own risk.

Once you have the `BOOTX64.efi` file copy it over to `TAILS-OSX/data`.

## Build the image

run 

```
./create-image.sh
```

You will be asked to select a volume that will be formatted and will contain
the TAILS live cd.

The script will then proceed to fetch TAILS, verify the signature, mount the
iso, move some files in the ISO over to the USB disk and then configure grub
properly.

Once you have finished this you will have a usb disk you can boot by holding
down the alt-option key at startup.

## References

* https://github.com/globaleaks/GlobaLeaks/issues/345

Mainly inspired by:

* http://fedorasolved.org/Members/jmontleon/installing-fedora-16-on-macbooks-using-grub2-efi

Misc links:

* http://carlton.oriley.net/blog/?p=15

* http://studyblast.wordpress.com/2011/08/14/guide-mac-os-x-lion-how-to-boot-a-linux-live-system-from-a-usb-drive-how-to-update-any-ocz-ssds-firmware/

* http://superuser.com/questions/236891/how-can-one-create-a-bootable-linux-usb-key-that-works-on-mac-intel-64-bit-cpu



