# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
properties() { '
kernel.string=nabu Kernel by Kuugo
device.name1=nabu
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
'; }
block=boot;
is_slot_device=1;
ramdisk_compression=auto;
. tools/ak3-core.sh;
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
dump_boot;
if [ -d $ramdisk/overlay ]; then
	rm -rf $ramdisk/overlay;
fi;
# patch_cmdline firmware_class.path firmware_class.path=/vendor/firmware_mnt/image
# patch_cmdline androidboot.selinux androidboot.selinux=permissive
# patch_cmdline ramoops_memreserve ramoops_memreserve=8M
	write_boot;

## vendor_boot shell variables
block=/dev/block/bootdevice/by-name/vendor_boot;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# reset for vendor_boot patching
reset_ak;

# vendor_boot install
dump_boot;

write_boot;
## end vendor_boot install