#!/bin/bash

################################################################################
# Args:
# $1 - flash type (NOR or NAND)
# $2 - flash size (0xXXXXXXXX - 8 digits hex number starting with 0x)
# $3 - bootargs (should contain 'mtdparts')
# $4 - UBI partition index shift (i.e. when system has another MTD device(s) before
#      the partitions on the flash mentioned in bootargs - see PLC240)
# Optional:
# $5 - MACH from configvars.mk (at91, am35), default - at91
# $6 - path to directory where to place result script, optional,
#      default - current dir
# $7 - path to mkimage utility, optional, default - current dir
################################################################################

################################################################################
# Pre-set configuration

# off_images - specifies fs images' names supported by 'off' command.
# These names are used to build respective script variables
off_images="l1 ub kern rfs ufs"

# part_name_XXX - list of possible partition names respective to the 
# supported images (above)
img_part_name_l1="xloader"	# bootstrap for AT91SAM9263 is not supported
img_part_name_ub="u-boot"
img_part_name_kern="kernel"
img_part_name_rfs="rootfs cramfs"
img_part_name_ufs="userfs"

img_part_file_l1="MLO"
img_part_file_ub="uboot.bin u-boot.bin"
img_part_file_kern="uImage.bin uImage"
img_part_file_rfs=plc.fs
img_part_file_ufs=user.fs

# in hex w/o starting 0x
flash_start_nor=10000000
flash_start_nand=0

mach_list="at91 am35"

################################################################################
# Set script arguments' vars

flash_type=$1
flash_start=
flash_size=${2:-0}
boot_args=$3
ubi_shift=${4:-0}
mach=${5:-at91}
dir_result=${6:-.}
dir_mkimage=${7:-.}
script_name=off_script

script_src_file=$dir_result/$script_name.txt
script_file=$dir_result/$script_name
mkimage=$dir_mkimage/mkimage
wiki_file=$dir_result/wiki.txt

################################################################################
# Functions

# $1 - message to print
exit_err()
{
	echo "Error: $1"
	exit 1
}

is_pa_hex_number()
{
	local num=$1
	if [[ "$num" =~ ^0x[0-9a-fA-F]{8}$ ]]; then
		local pa_num=$((num / 0x1000 * 0x1000))
		pa_num=`printf 0x%08X $pa_num`
		if [ "$num" = "$pa_num" ]; then
			return 1
		fi
	fi
	return 0
}

# $1 - item
# $2 - list
# return 0 - not in list, 1 - in list
is_item_in_list()
{
	for item in $2; do
		if [ "$1" = "$item" ]; then
			return 1
		fi
	done
	return 0
}

# $1 - image name from $off_images
# $2 - name of result var: 0-based index, -1 is error
lookup_img_part_index()
{
	local img=$1
	local img_part_name_var="img_part_name_$img"
	local result_var=$2
	
	#echo "img=$img"
	#echo "img_part_name_var=$img_part_name_var"
	
	eval $result_var=-1
	
	if [ -z "${!img_part_name_var}" ]; then
		#echo "${img_part_name_var} is not set"
		return
	fi
	
	local index=0
	while [ $index -lt $ba_part_count ]; do
		is_item_in_list ${ba_part_name[$index]} "${!img_part_name_var}"
		if [ $? -eq 1 ]; then
			eval $result_var=\$index
			break
		fi
		index=$((index + 1))
	done
}

set_part_params()
{
	local index=0
	local start=0
	local total_size=$((flash_size + 0))
	local ubi_root_exists=0

	while [ $index -lt $ba_part_count ]; do
		ba_part_start[$index]=`printf %X $((flash_start + $start))`
		
		# "-" is possible as size of the last partition
		if [ "${ba_part_size[$index]}" = "-" ]; then
			if [ "$flash_type" = "NOR" ]; then
				ba_part_sz[$index]=$((total_size - $start))
				ba_part_size[$index]=`printf %X ${ba_part_sz[$index]}`
				
			else
				ba_part_sz[$index]=0 #unknown
				ba_part_size[$index]=""
			fi
		else
			ba_part_sz[$index]=$((ba_part_size[$index] + 0))
			ba_part_size[$index]=`echo ${ba_part_size[$index]}|cut -c 3-`
		fi

		if [ "$flash_type" = "NOR" ]; then
			ba_part_end[$index]=`printf %X $((flash_start + $start + ${ba_part_sz[$index]} - 1))`
		fi

#		printf "%s: start=%s, size=%s, sz=0x%X, end=%s\n" \
#			${ba_part_name[$index]} ${ba_part_start[$index]} ${ba_part_size[$index]} \
#			${ba_part_sz[$index]} ${ba_part_end[$index]}
		
		start=$((start + ${ba_part_sz[$index]}))
		
		# set ubi opts
		is_item_in_list "$((index + $ubi_shift))" "$ba_ubi_parts"
		if [ $? -eq 1 ]; then
			ba_part_ubi_vol[$index]=`echo ${ba_part_name[$index]}|cut -c 1`fs
			if [ -n "$ba_ubi_root" -a "$ba_ubi_root" = "${ba_part_ubi_vol[$index]}" ]; then
				ubi_root_exists=1
			fi
		fi
		
		index=$((index + 1))
	done
	
	# perform check whole sum of partition sizes should not be > than flash size
	if [ $start -gt $total_size ]; then
		local msg=`printf "Sum of partitions: 0x%X > flash size: 0x%X" $start $total_size`
		exit_err "$msg"
	fi
	
	# check if ubi root partition exists when ubifs is used for root
	if [ -n "$ba_ubi_root" -a $ubi_root_exists -ne 1 ]; then
		exit_err "failed to find a ubifs partition for root ubifs volume '$ba_ubi_root'"
	fi
}
################################################################################
# Check arguments

[ "$flash_type" != "NOR" -a "$flash_type" != "NAND" ] && exit_err "Invalid flash type speicifed"
if [ "$flash_type" = "NOR" ]; then
	flash_start="0x$flash_start_nor"
else
	flash_start="0x$flash_start_nand"
fi

is_pa_hex_number $flash_size
[ $? -ne 1 ] && exit_err "Invalid flash size (not page-aligned 8-digit hex number)"

! [[ "$boot_args" =~ mtdparts ]] && exit_err "Invalid bootargs argument"

is_item_in_list $mach "$mach_list"
[ $? -eq 0 ] && exit_err "MACH '$mach' is not supported"

if [ ! -d $dir_result ]; then
	mkdir -p $dir_result
	[ $? -ne 0 ] && exit_err "Failed to make non-existent result dir"
fi

[ ! -x $mkimage ] && exit_err "Failed to find mkimage"

################################################################################
# Parse bootargs, sets the next vars:
#
# ba_ubi_root - name of ubi volume for rootfs (for additional check)
# ba_ubi_parts = "N N.." - list of ubi partitions indexes (each index is 0-based), may be empty.
#                The index of the respective partitions for the kernel may be shifted by $ubi_shift
# ba_part_count - number of partitions
# ba_part_name[], ba_part_size[] - 0-based arrays of partition properties (size of each is ba_part_count)
eval `echo $boot_args | gawk '
{
	if (match($0, /root=ubi[0-9]:([^'\''[:space:]]+)/, m)) {
		printf "ba_ubi_root=%s\n", m[1]
	}
		
	line = $0
	ubi_count = 0
	while (match(line, /ubi.mtd=([0-9])(.*)$/, m)) {
		ubi_parts[ubi_count] = m[1]
		line = m[2]
		ubi_count++
	}
	
	
	printf "ba_ubi_parts='\''"
	for (i = 0; i < ubi_count; i++) {
		printf "%d ", ubi_parts[i]
	}
	printf "'\''\n"

	parts_count = 0
	if (match($0, /(mtdparts=([^:]+):([^'\''[:space:]]+))/, m)) {
		printf "ba_mtd_parts=\"%s\"\n", m[1]
		printf "ba_mtd_id=%s\n", m[2]
		line = m[3]
		
		while (match(line, /^((0x[[:xdigit:]]+|-)[(]([[:alpha:]-]+)[)])[,[:space:]]?(.*)$/, m)) {
			parts[parts_count,0] = m[3]
			parts[parts_count,1] = m[2]
			line = m[4]
			parts_count++
		}
	}
	
	printf "ba_part_count=%d\n", parts_count
	for (i = 0; i < parts_count; i++) {
		printf "ba_part_name[%d]=%s\n", i, parts[i,0]
		printf "ba_part_size[%d]=%s\n", i, parts[i,1]
	}

}
'`

# check after boot args parsed

[ $ba_part_count -eq 0 ] && exit_err "Failed to parse bootargs - partitions weren't detected"

# calculate rest of settings: start, size, end, ubi vol names (flash- and board- specific settings)
set_part_params

# compile bootcmd
part_index=
lookup_img_part_index "kern" part_index
[ $part_index -lt 0 ] && exit_err "failed to determine kernel partition start"

if [ "$flash_type" = "NOR" ]; then
#	boot_cmd="'cp.b ${ba_part_start[$part_index]} '\$off_fileaddr' \$kern; bootm '\$off_fileaddr"
	boot_cmd="'bootm ${ba_part_start[$part_index]}'"
else
	boot_cmd="'nand read '\$off_fileaddr' ${ba_part_start[$part_index]} \$kern; bootm '\$off_fileaddr"
fi

################################################################################
# Generate flash script source

########################################
# function for making code for an image

# $1 - image name from $off_images
make_img_code()
{
	local img=$1
	local flag="off_$img"
	local img_file_var="img_part_file_$img"
	local force_ubifs=$2

	part_index=
	lookup_img_part_index $img part_index

	if [ $part_index -lt 0 ]; then
		echo "warning: image '$img' is not supported - do nothing for it"
		return
	fi
	if [ -z "${!img_file_var}" ]; then
		echo "warning: no file name defined for image '$img'"
		return
	fi

	local cmd_on_download=
	local cmd_protectoff=
	local cmd_erase=
	local cmd_write=

	if [ "$flash_type" = "NOR" ]; then
		cmd_protectoff="protect off ${ba_part_start[$part_index]} ${ba_part_end[$part_index]}"
		cmd_erase="erase ${ba_part_start[$part_index]} ${ba_part_end[$part_index]}"

		if [ "$force_ubifs" = "1" -a -n "${ba_part_ubi_vol[$part_index]}" ]; then
			cmd_on_download="setenv mtdids 'nor0=$ba_mtd_id';setenv mtdparts '$ba_mtd_parts';saveenv"
			cmd_write="ubi part ${ba_part_name[$part_index]}"
			cmd_write="$cmd_write;ubi create ${ba_part_ubi_vol[$part_index]}"
			cmd_write="$cmd_write;ubi write \$off_loadaddr ${ba_part_ubi_vol[$part_index]} \$filesize"
		else
			cmd_write="cp.b \$off_loadaddr ${ba_part_start[$part_index]} \$filesize"
		
			if [ "$img" = "kern" ]; then
				cmd_on_download="setenv kern \$filesize;saveenv"
			fi
		fi
	else
		cmd_erase="nand erase ${ba_part_start[$part_index]} ${ba_part_size[$part_index]}"

		# UBI partition ?
		if [ -z "${ba_part_ubi_vol[$part_index]}" ]; then
			# not UBI
			cmd_on_download="setexpr filesize_pa \$filesize / 1000;setexpr filesize_pa \$filesize_pa * 1000"
			cmd_on_download="$cmd_on_download;if test 0x\$filesize_pa -ne 0x\$filesize; then setexpr filesize_pa \$filesize_pa + 1000; fi"
			
			cmd_write="nand write \$off_loadaddr ${ba_part_start[$part_index]} \$filesize_pa"
			if [ "$mach" = "am35" -a "$img" = "l1" ]; then
				# write xloader twice - at 0 and 20000 offset
				cmd_write="$cmd_write;nand write \$off_loadaddr 20000 \$filesize_pa"
			fi
		else
			# is UBI
			cmd_on_download="setenv mtdids 'nand0=$ba_mtd_id';setenv mtdparts '$ba_mtd_parts';saveenv"
			cmd_write="ubi part ${ba_part_name[$part_index]}"
			cmd_write="$cmd_write;ubi create ${ba_part_ubi_vol[$part_index]}"
			cmd_write="$cmd_write;ubi write \$off_loadaddr ${ba_part_ubi_vol[$part_index]} \$filesize"
		fi

		if [ "$img" = "kern" ]; then
			cmd_on_download="$cmd_on_download;setenv kern \$filesize_pa;saveenv"
		fi
		
		if [ "$mach" = "am35" ]; then
			if [ "$img" = "l1" ]; then
				cmd_write="nandecc hw;$cmd_write"
			else
				cmd_write="nandecc bch4_sw;$cmd_write"
			fi
		fi
	fi

#----------------------------------
# append section to the result file

cat >> $script_src_file << END
# Flash: ${ba_part_name[$part_index]}
if test "1\$$flag" -eq 11; then
	off_dl_ok=0
END

cond=""
for f in ${!img_file_var}; do
cat >> $script_src_file << END
	${cond}if tftp \$off_loadaddr \${off_subdir}$f; then
		off_dl_ok=1
END
cond="el"
done
cat >> $script_src_file << END
	fi

	if test \$off_dl_ok -eq 1; then
		$cmd_on_download
		$cmd_protectoff
		setenv off_iter 2
		off_erase=0
		while test \$off_iter -gt 0; do
			if $cmd_erase; then
				setenv off_iter 0
				off_erase=1
			else
				setexpr off_iter \$off_iter - 1
			fi
		done
		if test \$off_erase -eq 1; then
			$cmd_write
			off_ok="\$off_ok $1"
		else
			off_fail="\$off_fail $1"
		fi
	else
		off_fail="\$off_fail $1"
	fi
fi

END

# end of item section
#----------------------------------

# append item to wiki-check file
#cat >> $wiki_file << END
## Flash: ${ba_part_name[$part_index]}
#tftp \$off_loadaddr \${off_subdir}${!img_file_var}
#$cmd_on_download
#$cmd_protectoff
#$cmd_erase
#$cmd_write
#
#END
}
# end of make_img_code()

#######################
# Generate the script

# off_loadaddr is shifted from script load addr end by max 0x1000 bytes

cat > $script_src_file << END
# Auto-generated Owen Firmware Flash script
off_ok=
off_fail=
off_fileaddr=\$fileaddr
setexpr off_loadaddr \$fileaddr + \$filesize
setexpr off_loadaddr \$off_loadaddr \& FFFFF000
setexpr off_loadaddr \$off_loadaddr + 1000

END

if [ "$mach" = "at91" -a "$flash_type" = "NOR" ]; then
	for img in $off_images; do
		if [ "$img" = "ufs" ]; then
			cat >> $script_src_file << END
# FIX FOR AT91 BOARDS FLASHING
if test "1\$off_ub" -eq 11 -o "1\$off_ubflash" -eq 11; then
	off_ubflash=1
	if test "1\$off_ufs" -eq 11; then
		off_rfs=0
		off_ufs=0
		echo "U-BOOT IS SCHEDULED TO FLASH - USERFS FLASHING IS CANCELED"
	fi
fi

END
			ubifs_present=1
			break
		fi
	done
fi



if [ "$mach" = "am35" ]; then
cat >> $script_src_file << END
# FIX FOR VARISCITE BOARDS FLASHING
if test "1\$off_l1" -eq 11 -o "1\$off_l1flash" -eq 11; then
	off_l1flash=1
	if test "1\$off_rfs" -eq 11 -o "1\$off_ufs" -eq 11; then
		off_rfs=0
		off_ufs=0
		echo "XLOADER IS SCHEDULED TO FLASH - ROOTFS AND USERFS FLASHING IS CANCELED"
	fi
fi

END
fi

if [ "$mach" = "at91" ]; then
batmp=$(echo "$boot_args" | sed 's,mem=[^ ]*,,')
boot_args_cmd=$(cat <<EOF
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
	setenv bootargs "$batmp mem=\$mem"
EOF
)
else
boot_args_cmd=$(cat <<EOF
	setenv bootargs "$boot_args"
EOF
)
fi

cat >> $script_src_file << END
# set up boot command
if test "1\$off_bc" -eq 11; then
	setenv bootcmd $boot_cmd
	saveenv
	off_ok="\$off_ok bootcmd"
fi

# set up boot args (ba_orig & dbg_state used by plc304x)
if test "1\$off_ba" -eq 11; then
$boot_args_cmd
	setenv ba_orig
	setenv dbg_state
	saveenv
	off_ok="\$off_ok bootargs"
fi

END

# start wiki-check file
#cat > $wiki_file << END
#setenv bootcmd $boot_cmd
#setenv bootargs '$boot_args'
#
#END

for img in $off_images; do
	unset force_ubi
	[ "$flash_type" = "NOR" -a "$img" = "ufs" ] && force_ubi=1
	make_img_code $img $force_ubi
done

cat >> $script_src_file << END
# clean up and report
setenv off_loadaddr
setenv filesize_pa
setenv off_iter
setenv off_erase
saveenv
if test "\${off_ok}1" -ne 1; then
	echo "Updated successfully: \$off_ok"
fi
if test "\${off_fail}1" -ne 1; then
	echo "Update failed: \$off_fail"
fi

END

if [ "$mach" = "at91" -a "$ubifs_present" = "1" ]; then
cat >> $script_src_file << END
# FIX FOR AT91 BOARDS FLASHING
if test "1\$off_ub" -eq 11; then
	echo "U-BOOT HAS BEEN FLASHED. RESET REQUIRED BEFORE FLASHING USERFS."
fi

END
fi

if [ "$mach" = "am35" ]; then
cat >> $script_src_file << END
# FIX FOR VARISCITE BOARDS FLASHING
if test "1\$off_l1flash" -eq 11; then
	echo "XLODER HAS BEEN FLASHED. RESET REQUIRED BEFORE FLASHING ROOTFS OR USERFS."
fi

END
fi

################################################################################
# Generate image of the script from source

$mkimage -T script -C none -n off -d $script_src_file $script_file

# cleanup
rm $script_src_file

################################################################################
# DEBUG
#set

exit 0
