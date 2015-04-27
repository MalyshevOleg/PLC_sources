#!/bin/bash
# $1 - dst file
# $2 - machine type
# $3 - type of firmware (full, u-boot)
# $4 - board name check
# $5 - board name to display in board block
# $6 - bootargs
# $7 - version

# at91-nor specific
# $8 - flash_base
# $9 - flash_size

# mtdids, mtdparts is set before very first block is updating
# bootarg is set after kernel block is updating - it need to load by partition name instead of address in nand

[ $# -lt 7 ] && exit 1

dst_file=$1; shift
mach=$1; shift
fw=$1; shift
board=$1; shift
board_pr=`echo "$1" | tr 'a-z' 'A-Z'`; shift
bootargs=$1; shift
version=$1; shift
at91_flash_base=$1; shift
at91_flash_size=$1; shift
at91_flash_erase_size=$1; shift


uboot_img=boot/u-boot.bin
unset nand_erase_part_suffix
unset nand_write_part_suffix
unset ubi_part_subpage_size

rootfs_part="rootfs"
rootfs_vol="rfs"
userfs_part="userfs"
userfs_vol="ufs"
mtdid="nand0"

case $mach in
	am35) erase_size_l=126976; erase_size_p=131072 ;;
	am33) erase_size_l=126976; erase_size_p=131072; uboot_img=boot/u-boot.img; nand_erase_part_suffix=.part; ubi_part_subpage_size=2048 ;;
	s3c) erase_size_l=129024; erase_size_p=131072 ;;
	s3c_k9f1g08u0e) erase_size_l=126976; erase_size_p=131072 ; ubi_part_subpage_size=2048 ;;
  	at91-nor) erase_size_l=$at91_flash_erase_size;erase_size_p=$at91_flash_erase_size;flash_base=$at91_flash_base;flash_size=$at91_flash_size;mtdid="nor0";rootfs_vol="-";;
	*) echo "invalid mach"; exit 1;;
esac

unset pnm psz
mtdp=(`echo "$bootargs" | sed -r 's,^.*mtdparts=([^ ]*):([^ ]*).*$,\1 \2,'`)
for i in `echo ${mtdp[1]} | sed -r 's/,/ /g'`; do
	tmp=(`echo $i | sed -r 's,^(.*)\((.*)\)$,\1 \2,'`)
	pnm=(${pnm[*]} ${tmp[1]})
	psz=(${psz[*]} ${tmp[0]})
done
bootargs=${bootargs/mtdparts=${mtdp[0]}:${mtdp[1]}/++PLACE_FOR_MTDPARTS++}

update_part_size()
{
	for ((i=0;i<"${#pnm[*]}";i++)); do
		[ "${pnm[$i]}" = "$1" -a "${psz[$i]}" != "-" ] && [ `printf "%u" ${psz[$i]} ` -lt `printf "%u" $2` ] && {
			psz[$i]=`printf 0x%x $2`
			break
		}
	done
}

get_part_start() {
	# $1 - part name
	local base=$flash_base
	for ((i=0;i<"${#pnm[*]}";i++)); do
		[ "${pnm[$i]}" = "$1" ] && { printf %x $base; break; }
		[ "${psz[$i]}" = "-" ] && base=$(($flash_base+$flash_size)) || base=$((base+${psz[$i]}))
	done
}

get_part_dims() {
	# $1 - part name
        local base=$flash_base
        for ((i=0;i<"${#pnm[*]}";i++)); do
		local base_prev=$base
		[ "${psz[$i]}" = "-" ] && base=$(($flash_base+$flash_size)) || base=$((base+${psz[$i]}))
		[ "${pnm[$i]}" = "$1" ] && { printf "%x %x" $base_prev $((base-1)); break; } 
	done
}

build_mtdparts()
{
	local i mtdparts
	for ((i=0;i<"${#pnm[*]}";i++)); do
		if [ "${psz[$i]}" = "-" ]; then
			mtdparts=`printf "%s-(%s)," "${mtdparts}" "${pnm[$i]}"`
		else
			mtdparts=`printf "%s0x%x(%s)," "${mtdparts}" "${psz[$i]}" "${pnm[$i]}"`
		fi
	done
	echo "mtdparts=${mtdp[0]}:$mtdparts" | sed -r 's/,$//'
}

write_num() {
  	printf "%08x" $2 | xxd -g0 -r -p | perl -0777e 'print scalar reverse <>' >>$1
}

write_hex() {
	echo $2 | xxd -g0 -r -p | perl -0777e 'print scalar reverse <>' >>$1
}

write_file() {
	local sz szb
	sz=0
	[ -n "$2" ] && sz=`stat -c %s "$2"`
	szb=$sz
	[ -n "$3" ] && szb=$((($sz/$erase_size_p+($sz%$erase_size_p?1:0))*$erase_size_p))
	write_num $1 $szb
	[ -n "$2" ] && cat "$2" >>$1
	[ $szb -gt $sz ] && dd if=/dev/zero bs=$(($szb-$sz)) count=1 2>/dev/null | tr "\000" "\377" >>$1
}

write_string() {
	write_num $1 "${#2}"
	echo -n "$2" | iconv -f utf-8 -t cp866 >>$1
}


calc_blocks() {
	echo $(($1/$2+($1%$2?1:0)))
}

calc_ubi_overhead() {
	# overhead calculation http://www.linux-mtd.infradead.org/doc/ubi.html#L_overhead
	echo $((($1+4)+($1+4)*20/1024+(($1+4)*20%1024?1:0)))
}

##############################################################################
#### 
##############################################################################

unset is_uboot_fw

case "$fw" in
	full) blocks="u-boot,-,$uboot_img;kernel,-,install/uImage.bin;$rootfs_part,$rootfs_vol,plc.fs;$userfs_part,$userfs_vol,user.fs";;
	u-boot|uboot) blocks="u-boot,-,$uboot_img"; is_uboot_fw=1 ;;
	*) echo "invalid fw type"; exit 1;;
esac

unset blkdesc
for b in `echo "$blocks" | sed -r 's,;, ,g'`; do
	tmp=(`echo "$b" | sed -r 's/,/ /g'`)
	part=${tmp[0]}
	ubivol=${tmp[1]}
	file=${tmp[2]}
	[ -f $file ] || { echo "no file $file"; exit; }
	sz=`stat -c %s $file`
	if [ "$ubivol" = "-" ]; then
		szb=`calc_blocks $sz $erase_size_p`
	else
		szb=`calc_blocks $sz $erase_size_l`
		szb=`calc_ubi_overhead $szb`
	fi
	sze=$(($szb * $erase_size_p))
	update_part_size $part $sze
	[ "$part" = "kernel" ] && kern=$sz
	blkdesc="$blkdesc $part;$ubivol;$file"
done

mtdparts=`build_mtdparts`
bootargs=${bootargs/++PLACE_FOR_MTDPARTS++/`build_mtdparts`}

#echo $bootargs

##############################################################################
#### board config block
##############################################################################

if [ -f "../.mkfw-disable-board-check" ]; then
cmd_board=$(cat <<EOF
setenv mtdids "${mtdid}=${mtdp[0]}"
setenv mtdparts "$mtdparts"
setenv bootargs "$bootargs eth=\${ethaddr}" 
EOF
)
elif [ "$mach" = "at91-nor" ]; then
bootargs=$(echo "$bootargs" | sed 's,mem=[^ ]*,,')
cmd_board=$(cat <<EOF
[ "\$BOARD" = "$board" ] || die "\$MSG_MISMATCH $board_pr"
setenv mtdids "${mtdid}=${mtdp[0]}"
setenv mtdparts "$mtdparts"
mw.l 0x20000000 0xdeadbeef
mw.l 0x22000000 0xbeefdead
mem=32M
if itest *0x22000000 == 0xbeefdead; then
	mem=64M
fi
if itest *0x22000000 == 0xdeadbeef; then
	mem=32M
fi
echo "Memory detected: \$mem"
setenv bootargs "$bootargs mem=\$mem"
EOF
)
else
cmd_board=$(cat <<EOF
[ "\$BOARD" = "$board" ] || die "\$MSG_MISMATCH $board_pr"
setenv mtdids "${mtdid}=${mtdp[0]}"
setenv mtdparts "$mtdparts"
setenv bootargs "$bootargs eth=\${ethaddr}"
EOF
)
fi

##############################################################################
#### binary data partition
##############################################################################

if [ "$mach" = "at91-nor" ]; then
	cmd_raw=$(cat <<EOF
pb "\$MSG_ERASE \$BLOCK"
protect off %PART_DIMS% || die "\$MSG_PROTECT_FAIL \$BLOCK"
erase %PART_DIMS% || die "\$MSG_ERASE_FAIL \$BLOCK"
pb "\$MSG_UPDATE \$BLOCK"
cp.b \$BUFFER %PART_START% \$SIZE || die "\$MSG_UPDATE_FAIL \$BLOCK"
protect on %PART_DIMS% || die "\$MSG_PROTECT_FAIL \$BLOCK"
pb off
EOF
)
else
	cmd_raw=$(cat <<EOF
pb "\$MSG_ERASE \$BLOCK"
nand erase${nand_erase_part_suffix} %PARTITION% || die "\$MSG_ERASE_FAIL \$BLOCK"
pb "\$MSG_UPDATE \$BLOCK"
nand write${nand_write_part_suffix} \$BUFFER %PARTITION% \$SIZE || die "\$MSG_UPDATE_FAIL \$BLOCK"
pb off
EOF
)
fi

##############################################################################
#### ubi partition
##############################################################################

cmd_ubi=$(cat <<EOF
pb "\$MSG_ERASE \$BLOCK"
nand erase${nand_erase_part_suffix} %PARTITION% || die "\$MSG_ERASE_FAIL \$BLOCK"
pb off
ubi part %PARTITION% ${ubi_part_subpage_size} || die "\$MSG_UBIPART_FAIL \$BLOCK"
ubi create %VOLUME% || die "\$MSG_UBIPART_FAIL \$BLOCK"
pb "\$MSG_UPDATE \$BLOCK"
ubi write \$BUFFER %VOLUME% \$SIZE || die "\$MSG_UPDATE_FAIL \$BLOCK"
pb off
EOF
)

cmd_ubi_nor=$(cat <<EOF
pb "\$MSG_ERASE \$BLOCK"
erase %PART_DIMS% || die "\$MSG_ERASE_FAIL \$BLOCK"
pb off
ubi part %PARTITION% ${ubi_part_subpage_size} || die "\$MSG_UBIPART_FAIL \$BLOCK"
ubi create %VOLUME% || die "\$MSG_UBIPART_FAIL \$BLOCK"
pb "\$MSG_UPDATE \$BLOCK"
ubi write \$BUFFER %VOLUME% \$SIZE || die "\$MSG_UPDATE_FAIL \$BLOCK"
pb off
EOF
)


##############################################################################
#### kernel partition
##############################################################################
if [ "$mach" = "at91-nor" ]; then
	cmd_kernel="${cmd_raw}
$(cat <<EOF
setenv bootcmd "bootm %PART_START%"
saveenv
EOF
)"
	cmd_kernel=${cmd_kernel//%PART_DIMS%/`get_part_dims "kernel"`}
	cmd_kernel=${cmd_kernel//%PART_START%/`get_part_start "kernel"`}
else
	cmd_kernel=$(cat <<EOF
pb "\$MSG_ERASE \$BLOCK"
nand erase${nand_erase_part_suffix} %PARTITION% || die "\$MSG_ERASE_FAIL \$BLOCK"
pb "\$MSG_UPDATE \$BLOCK"
nand write${nand_write_part_suffix} \$BUFFER %PARTITION% \$SIZE || die "\$MSG_UPDATE_FAIL \$BLOCK"
pb off
setenv bootcmd "nand read${part_suffix} \$fileaddr kernel \$SIZE; bootm \$fileaddr"
saveenv
EOF
)
fi
           
##############################################################################
#### u-boot partition
##############################################################################

if [ "$mach" = "at91-nor" ]; then
	bootcmd="fwu `basename $dst_file`"
	cmd_uboot=$(cat <<EOF
${cmd_raw}
EOF
);
	cmd_uboot=${cmd_uboot//%PART_DIMS%/`get_part_dims "u-boot"`}
	cmd_uboot=${cmd_uboot//%PART_START%/`get_part_start "u-boot"`}
elif [ "$mach" = "am35" -o "$mach" = "am33" ]; then
cmd_uboot=$(cat <<EOF
pb "\$MSG_ERASE \$BLOCK"
nand erase${nand_erase_part_suffix} u-boot || die "\$MSG_ERASE_FAIL \$BLOCK"
pb "\$MSG_UPDATE \$BLOCK"
nand write${nand_write_part_suffix} \$BUFFER u-boot \$SIZE || die "\$MSG_UPDATE_FAIL \$BLOCK"
pb off
saveenv
EOF
)
elif [ "$mach" = "s3c" -o "$mach" = "s3c_k9f1g08u0e" ]; then
	cmd_uboot=$(cat <<EOF
pb "\$MSG_ERASE \$BLOCK"
nand erase${nand_erase_part_suffix} u-boot || die "\$MSG_ERASE_FAIL \$BLOCK"
nand erase${nand_erase_part_suffix} env || die "\$MSG_ERASE_FAIL \$BLOCK"
pb "\$MSG_UPDATE \$BLOCK"
nand write${nand_write_part_suffix} \$BUFFER u-boot \$SIZE || die "\$MSG_UPDATE_FAIL \$BLOCK"
pb off
saveenv
EOF
)
fi

if [ -n "$is_uboot_fw" ]; then
	cmd_uboot=$(cat <<EOF
$cmd_uboot
reset
EOF
)
fi


##############################################################################
#### 
##############################################################################

echo -n >$dst_file

unset files

write_block() {
	tmpfile=`mktemp tmpXXXXXX`
	write_string $tmpfile $1
	cmd="$2"
	len=$((${#1}+${#2}))
	[ "$((len % 4))" != "0" ] && cmd="$cmd$(echo "    " | cut -c 1-$((4 - len % 4)))"
	write_string $tmpfile "$cmd"
	write_file $tmpfile "$3" "$4"
	files="$files $tmpfile"
}

# 1st - check board block
write_block "BOARD" "$cmd_board" ""
# 2nd - loop for blocks
for blk in $blkdesc; do
	read part ubivol file sze << .EOF
$(echo $blk | tr ';' ' ')
.EOF
	name=`echo $part | tr 'a-z' 'A-Z'`
	if [ "$ubivol" != "-" -a "$mach" != "at91-nor" ]; then
		cmd="${cmd_ubi//\%PARTITION\%/$part}"
		cmd="${cmd//\%VOLUME\%/$ubivol}"
    		[ "$part" == "rootfs" ] && {
			cmd=$(cat <<EOF
$cmd
setenv rootfsver "$version"
saveenv
EOF
)
		}
    		write_block "$name" "$cmd" $file
	elif [ "$ubivol" != "-" -a "$mach" = "at91-nor" ]; then
		cmd="${cmd_ubi_nor//\%PART_DIMS\%/`get_part_dims "$part"`}"
		cmd="${cmd//\%PARTITION\%/$part}"
		cmd="${cmd//\%VOLUME\%/$ubivol}"
    		[ "$part" == "rootfs" ] && {
			cmd=$(cat <<EOF
$cmd
setenv rootfsver "$version"
saveenv
EOF
)
		}
      		write_block "$name" "$cmd" $file
  	elif [ "$name" = "KERNEL" ]; then
    		cmd="${cmd_kernel//\%PARTITION\%/$part}"
    		write_block "$name" "$cmd" $file do_pad
  	elif [ "$name" = "U-BOOT" ]; then
		cmd="${cmd_uboot//\%PARTITION\%/$part}"
		write_block "$name" "$cmd" $file do_pad
	else
		if [ "$mach" = "at91-nor" ]; then
			cmd=${cmd_raw//%PART_DIMS%/`get_part_dims "$part"`}
			cmd=${cmd//%PART_START%/`get_part_start "$part"`}
			[ "$part" = "cramfs" ] && {
        			cmd=$(cat <<EOF
$cmd
setenv rootfsver "$version"
saveenv
EOF
)
      			}
      			write_block "$name" "$cmd" $file
    		else
      			cmd="${cmd_raw//\%PARTITION\%/$part}"
      			write_block "$name" "$cmd" $file
    		fi
  	fi
done
 

for f in $files; do
	cat $f >>$dst_file
	write_hex $dst_file `crc32 $dst_file`
	rm $f
done
