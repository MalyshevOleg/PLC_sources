#!/bin/sh
. /etc/functions

/bin/mount /proc
/bin/mount /sys
echo -n "Mounting /dev..."
/bin/mount -t tmpfs -o size=256k,mode=0755 tmpfs /dev
check_status
mkdir /dev/pts
/bin/mount /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
echo -n "Making device nodes..."
/sbin/mdev -s
check_status

/bin/mount -t tmpfs none /tmp
/bin/mount -t tmpfs none /var
if grep -q usbfs /proc/filesystems ; then
  if ! grep -q usbfs /proc/mounts ; then
    /bin/mount /proc/bus/usb
  fi
fi
mkdir /var/run
mkdir /var/lock
mkdir /var/log
# Make /var/lock world-writable
chmod a+w,+t /var/lock

/bin/mount -t tmpfs -o size=256k tmpfs /mnt/etcrw

CLEANETC=1
TFILE=/mnt/ufs/root/etc.tar

# Mount user fs
/bin/mount -t ubifs ubi1:ufs /mnt/ufs

if [ $? -eq 0 ] ; then
  tar -tf ${TFILE} > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    CLEANETC=0
  else
    CLEANETC=1
  fi
else
  # tmpfs as /root if userfs feels bad
  /bin/mount -t tmpfs tmpfs /mnt/ufs
  mkdir /mnt/ufs/root
fi

echo -n "Doing /etc/magic... "
if [ ${CLEANETC} -eq 0 ] ; then
  echo -n "restore is "
  tar -xf /mnt/ufs/root/etc.tar -C /mnt/etcrw
  check_status
else
  echo "done"
fi

/bin/mount -t aufs -o dirs=/mnt/etcrw=rw:/mnt/etcro=ro aufs /etc

MOUNT_ROOT=/mnt/ufs/media
if [ -e /dev/mmcblk0p1 ];
then
   echo -n "Mounting mmc card"
   sleep 1
   mkdir -p $MOUNT_ROOT/mmcblk0p1
   /bin/mount -t vfat -o sync /dev/mmcblk0p1 $MOUNT_ROOT/mmcblk0p1
fi
if [ -e /dev/sda ];
then
   sleep 1
   mkdir -p $MOUNT_ROOT/sda
   /bin/mount -t vfat -o sync /dev/sda $MOUNT_ROOT/sda
fi

if [ -e /dev/sda1 ];
then
   sleep 1
   mkdir -p $MOUNT_ROOT/sda1
   /bin/mount -t vfat -o sync /dev/sda1 $MOUNT_ROOT/sda1
fi
