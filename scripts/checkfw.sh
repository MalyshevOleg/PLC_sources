#!/bin/sh

[ -n "$1" ] || { echo "use with filename"; exit; }

unset files

src="$1"
[ -f "$src" ] || { echo "no file $src"; exit; }
file_size=`stat -c %s "$src"`

tmpfile=`mktemp /tmp/tmpXXXXXX`
file_ptr=0
while [ $file_ptr -lt $file_size ]; do
	sz=`dd if="$src" bs=1 skip=$file_ptr count=4 2>/dev/null | hexdump -e '/4 "%d"'`
	name=`dd if="$src" bs=1 skip=$((file_ptr+4)) count=$sz 2>/dev/null`
	file_ptr=$((file_ptr+4+sz))
	sz=`dd if="$src" bs=1 skip=$file_ptr count=4 2>/dev/null | hexdump -e '/4 "%d"'`
	IFS=`echo -n 'x' | tr 'x' '\377'` script=$(dd if="$src" bs=1 skip=$((file_ptr+4)) count=$sz 2>/dev/null)
	file_ptr=$((file_ptr+4+sz))
	sz=`dd if="$src" bs=1 skip=$file_ptr count=4 2>/dev/null | hexdump -e '/4 "%d"'`
	file_ptr=$((file_ptr+sz+4))
	dd if="$src" of="$tmpfile" bs=$file_ptr count=1 2>/dev/null
	crc_calc=`crc32 $tmpfile`
	file_ptr_end=$file_ptr
	crc=`dd if="$src" bs=1 skip=$file_ptr count=4 2>/dev/null | hexdump -e '/4 "%x"'`
	file_ptr=$((file_ptr+4))
	echo "$name;$sz;$crc;$crc_calc"
	echo "--- script ----------------------------------------"
	echo $script
	echo "--- script ----------------------------------------"
	echo
done
unlink $tmpfile
