
## Create the EFI bootloader

You should run the following command:

```
grub2-mkimage -d /usr/lib/grub2-efi/x86_64-efi/ -o BOOTX64.efi \
-O x86_64-efi --prefix /efi/boot part_gpt part_msdos lvm fat ext2 \
chain boot configfile normal minicmd linux reboot halt search \
gfxterm gfxmenu efi_gop efi_uga video loadbios gzio video_bochs \
video_cirrus echo true loadenv
```

Somebody claims to have the output of that commmand hosted here: https://sites.google.com/a/montleon.com/home/EFI.tar.gz.

Use at your own risk.


## References

* https://github.com/globaleaks/GlobaLeaks/issues/345

* http://carlton.oriley.net/blog/?p=15

* http://studyblast.wordpress.com/2011/08/14/guide-mac-os-x-lion-how-to-boot-a-linux-live-system-from-a-usb-drive-how-to-update-any-ocz-ssds-firmware/

* http://superuser.com/questions/236891/how-can-one-create-a-bootable-linux-usb-key-that-works-on-mac-intel-64-bit-cpu

* http://fedorasolved.org/Members/jmontleon/installing-fedora-16-on-macbooks-using-grub2-efi


