#!/sbin/busybox sh

start()
{
    echo "#####" > /tmp/turbo_repair.log
    echo "Turbo Repair started" >> /tmp/turbo_repair.log
    date >> /tmp/turbo_repair.log
    echo "#####" >> /tmp/turbo_repair.log
    echo " " >> /tmp/turbo_repair.log
}

repairsd()
{
    umount /sdcard
    umount /sd-ext
    if   [ "$2" == "1" ]; then
        echo " " >> /tmp/turbo_repair.log
        echo "### About to run fsck_msdos on microSD FAT32 partition... " >> /tmp/turbo_repair.log
        echo "###" >> /tmp/turbo_repair.log
        fsck_msdos -y /dev/block/mmcblk0p1 >> /tmp/turbo_repair.log
    elif [ "$2" == "2" ]; then
        echo " " >> /tmp/turbo_repair.log
        if [ -e /dev/block/mmcblk0p2 ]; then
            echo "### About to run e2fsck on microSD sd-ext partition... " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
            e2fsck -p -f -v /dev/block/mmcblk0p2 >> /tmp/turbo_repair.log
        else
            echo "### Skipped e2fsck on microSD sd-ext partition (not found) " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
        fi
    fi
}

fixpermissions()
{
    umount /sdcard
    mount -o rw /dev/block/mmcblk0p1 /sdcard
    umount /data
    echo " " >> /tmp/turbo_repair.log
    if [ "$2" == "1" ]; then
        echo "### About to repair permissions for Internal system... " >> /tmp/turbo_repair.log
        echo "###" >> /tmp/turbo_repair.log
        mount -t yaffs2 -o rw /dev/block/mtdblock0 /system >> /tmp/turbo_repair.log
        mount -t yaffs2 -o rw /dev/block/mtdblock1 /data >> /tmp/turbo_repair.log
        if [ -e /system/etc/init.d/11link2sd ]; then /sbin/sh /system/etc/init.d/11link2sd; fi
        /sbin/fix_permissions >> /tmp/turbo_repair.log
    else
        if [ -e /turbo/userdata$2.ext2.img ]; then
            echo "### About to repair permissions for Slot $2... " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
            mount -t ext2 -o rw,loop,noatime,nosuid,nodev  /turbo/system$2.ext2.img  /system >> /tmp/turbo_repair.log
            mount -t ext2 -o rw,loop,noatime,nosuid,nodev  /turbo/userdata$2.ext2.img  /data >> /tmp/turbo_repair.log
            if [ -e /system/etc/init.d/11link2sd ]; then /sbin/sh /system/etc/init.d/11link2sd; fi
            /sbin/fix_permissions >> /tmp/turbo_repair.log
        else
            echo "### Slot $2 has no userdata image, fix permissions skipped. " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
        fi
    fi
    umount /data
}

repairslot()
{
    umount /sdcard
    mount -o rw /dev/block/mmcblk0p1 /sdcard
    umount /system
    umount /data
    echo " " >> /tmp/turbo_repair.log
    if [ -e /sdcard/$3$2.ext2.img ]; then
        echo "### About to run e2fsck on $3 partition for Slot $2... " >> /tmp/turbo_repair.log
        echo "###" >> /tmp/turbo_repair.log
        e2fsck -p -f -v /sdcard/$3$2.ext2.img >> /tmp/turbo_repair.log
    else
        echo "### Slot $2 has no $3 image, e2fsck skipped. " >> /tmp/turbo_repair.log
        echo "###" >> /tmp/turbo_repair.log
    fi
}

finish()
{
    echo " " >> /tmp/turbo_repair.log
    echo "#####" >> /tmp/turbo_repair.log
    echo "Turbo Repair finished" >> /tmp/turbo_repair.log
    date >> /tmp/turbo_repair.log
    echo "#####" >> /tmp/turbo_repair.log
}

copylog()
{
    touch /tmp/turbo_repair.ready2copy
}

$1 $1 $2 $3

