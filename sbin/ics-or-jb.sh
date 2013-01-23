#!/sbin/busybox sh

if [ "$(grep -F "ro.build.version.release=" /system/build.prop | sed "s/ro.build.version.release=//g")" == "4.1.1" ] ||
   [ "$(grep -F "ro.build.version.release=" /system/build.prop | sed "s/ro.build.version.release=//g")" == "4.1.2" ]
then
  setprop turbo.mode jb
  echo jb
else
  setprop turbo.mode ics
  echo ics
fi
