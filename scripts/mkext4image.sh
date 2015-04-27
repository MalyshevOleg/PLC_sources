#!/bin/sh
# $1 - image
# $2 - directory
# $3 - size in 1K blocks
LD_PRELOAD=
[ $# -lt 3 ] && exit
dd if=/dev/zero of="$1" bs=1024 count=$3
/sbin/mkfs.ext4 -F "$1"
tmpdir=`mktemp -d mntXXXXXX`
fuse-ext2 -o rw,force "$1" $tmpdir 
tar cp --exclude=.svn -C $2 . | (cd $tmpdir; tar xp);
chown -R root.root $tmpdir/*
fusermount -u $tmpdir
rmdir $tmpdir
