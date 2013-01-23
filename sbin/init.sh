#!/sbin/busybox sh
set -x
_PATH="$PATH"
export PATH=/sbin
#export ANDROID_CACHE=/cache

cd /
busybox echo "[TURBO] Stage 1 begins" >>boot.log
busybox date >>boot.log
exec >>boot.log 2>&1
busybox rm /init

# device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev
busybox mount -t tmpfs -o size=10M,mode=0755 tmpfs /dev
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys
busybox mkdir -m 755 -p /tmp
busybox mount -t tmpfs -o size=10M,mode=0755 tmpfs /tmp

# create device nodes
busybox mknod -m 600 $BOOTREC_CACHE_NODE
busybox mknod -m 600 $BOOTREC_EVENT_NODE
busybox mknod -m 666 /dev/null c 1 3
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 /dev/block/mmcblk0p1 b 179 1
#busybox fdisk -l /dev/block/mmcblk0

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t yaffs2 $BOOTREC_CACHE /cache

# fixing CPU clocks to avoid issues in recovery
busybox echo 1024000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
busybox echo 122000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

if [ ! -e /cache/recovery/boot ]; then
    # trigger blue LED
    busybox echo 0 > $BOOTREC_LED_RED
    busybox echo 0 > $BOOTREC_LED_GREEN
    busybox echo 255 > $BOOTREC_LED_BLUE
    # trigger superquick vibration
    busybox echo 80 > $BOOTREC_VIBRATOR

    # keycheck
    busybox cat $BOOTREC_EVENT > /dev/keycheck&
    busybox sleep 2

    # LED off
    busybox echo 0 > $BOOTREC_LED_RED
    busybox echo 0 > $BOOTREC_LED_GREEN
    busybox echo 0 > $BOOTREC_LED_BLUE
fi

busybox echo 200 > $BOOTREC_LED_RED
busybox echo 200 > $BOOTREC_LED_GREEN
busybox echo 200 > $BOOTREC_LED_BLUE

# default ramdisk
load_image=/sbin/ramdisk-recovery.cpio

# bind-mount turbo data then unmount sdcard
busybox mkdir /sdcard
busybox mount /dev/block/mmcblk0p1 /sdcard
busybox mkdir /turbo
busybox mount -o bind /sdcard/turbo /turbo
busybox umount -l /sdcard
busybox rm -rf /sdcard

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox echo "[TURBO] Entering Boot Menu..." >>boot.log
	busybox rm /cache/recovery/boot
    busybox touch /tmp/bootrec
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

if [ -e /tmp/bootrec ]
then
    busybox rm /tmp/bootrec
    if [ -e /turbo/cwm ]; then
        # cwm-recovery ramdisk
        rec_image=/sbin/ramdisk-cwm.cpio
	else
        # twrp-recovery ramdisk
        rec_image=/sbin/ramdisk-recovery.cpio
    fi
    load_image=$rec_image
    busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
else
    # Prepare for normal boot
	busybox echo 'ANDROID BOOT' >>boot.log
    # Slot select
    if   [ -e /cache/multiboot1 ]
    then
        # Slot 1 (one time only)
        mode=$(busybox grep -F "mode=" /turbo/slot1mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Internal/Slot 1 (One-time only); Mode is $mode' >>boot.log
    elif [ -e /cache/multiboot2 ]
    then
        # Slot 2 (one time only)
        mode=$(busybox grep -F "mode=" /turbo/slot2mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 2 (One-time only); Mode is $mode' >>boot.log
    elif [ -e /cache/multiboot3 ]
    then
        # Slot 3 (one time only)
        mode=$(busybox grep -F "mode=" /turbo/slot3mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 3 (One-time only); Mode is $mode' >>boot.log
    elif [ -e /cache/multiboot4 ]
    then
        # Slot 4 (one time only)
        mode=$(busybox grep -F "mode=" /turbo/slot4mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 4 (One-time only); Mode is $mode' >>boot.log
    elif [ -e /turbo/defaultboot_2 ]
    then
        # Slot 2 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot2mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 2 (Default); Mode is $mode' >>boot.log
    elif [ -e /turbo/defaultboot_3 ]
    then
        # Slot 3 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot3mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 3 (Default); Mode is $mode' >>boot.log
    elif [ -e /turbo/defaultboot_4 ]
    then
        # Slot 4 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot4mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 4 (Default); Mode is $mode' >>boot.log
    else
        # Internal/Slot 1 (default)
        mode=$(busybox grep -F "mode=" /turbo/slot1mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Internal/Slot 1 (Default); Mode is $mode' >>boot.log
    fi
    if [ "$mode" == "" ]
    then
        busybox echo '[TURBO] Error - mode "$mode" is not valid! Entering Recovery.' >>boot.log
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=$rec_image
    elif [ "$mode" == "JB-AOSP" ]
    then
        busybox echo 1 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-jb.cpio
    elif [ "$mode" == "ICS-AOSP" ]
    then
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-ics.cpio
    elif [ "$mode" == "ICS-Stock" ]
    then
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-ics-stock.cpio
    else
        busybox echo '[TURBO] Error - mode "$mode" is not valid! Entering Recovery.' >>boot.log
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=$rec_image
    fi
fi

# unpack the ramdisk
busybox cpio -d -i -F ${load_image}

# switch LED off
busybox echo 0 > $BOOTREC_LED_RED
busybox echo 0 > $BOOTREC_LED_GREEN
busybox echo 0 > $BOOTREC_LED_BLUE

#busybox cp /boot.log /cache/boot_last.log

busybox umount -l /cache
#busybox rm -rf /cache
busybox umount -l /proc
busybox umount -l /sys
#busybox umount -l /tmp

#busybox rm -rf /dev/*
busybox date >>boot.log
export PATH="${_PATH}"
exec /init
