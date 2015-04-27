#!/bin/sh
LD_PRELOAD=
BLKSZ=1024
SECTOR=512
FIRSTOFF=2048
[ $# -lt 1 ] && exit
dst=$1
src=""
totalsz=0
while shift; do
  [ -z "$1" ] && break
  src="$src $1"
  totalsz=$(($totalsz + `stat -c %s $1`))
done
totalblk=$(($totalsz / $BLKSZ + 1 + 2048))
start=$FIRSTOFF
for i in $src; do 
  sz=`stat -c %s $i`
  szblk=$(($sz / $SECTOR))
  end=$(($start + $szblk - 1))
  start=$(($end + 1))
done
dd if=/dev/zero of=$dst bs=$SECTOR count=$start
start=$FIRSTOFF
for i in $src; do 
  sz=`stat -c %s $i`
  szblk=$(($sz / 512))
  end=$(($start + $szblk - 1))
  { echo n; echo p; echo; echo $start; echo $end; echo w; } | /sbin/fdisk -u $dst
  start=$(($end + 1))
done
dd if=$dst of=mbr.bin bs=$SECTOR count=$FIRSTOFF
cat mbr.bin $src >$dst
rm mbr.bin
