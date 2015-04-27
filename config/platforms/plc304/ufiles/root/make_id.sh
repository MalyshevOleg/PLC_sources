#!/bin/sh

# make ID
# - 6 bytes MAC address (BE)
# - 4 bytes: 0, 0, 0, 0
# - any bytes - 0s
# - last 4 bytes: 0x55aa55aa (LE)

ID_FILE=$1

# edited by BuildSystem - specific PLC ID is defined
PLC_ID=0x55aa

h=$(($PLC_ID >> 8))
l=$(($PLC_ID & 0xff))
PLC_ID_STR=`printf "\\\x%02X\\\x%02X\n" $l $h`

# MAC addr
echo -ne `ifconfig eth0 | \
    awk '/HWaddr/ \
		{
			ORS = "";
			split($5, digits, ":"); 
			for (i = 0; i < 6; i++) {
				print "\\\x"digits[6-i];
				print x;
			}
		}'` >  $ID_FILE

# 0s x 4
echo -ne "\x00\x00\x00\x00" >> $ID_FILE

# ANY bytes, len=1024-6-4-4=1010
i=0
while [ $i -lt 101 ]; do
    echo -ne "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" >> $ID_FILE
    #echo -ne "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> $ID_FILE
    i=$((i + 1))
done

# 0x55aaXXYY (LE): 0x55aa - signature, 0xXXYY - PLC ID
echo -ne "${PLC_ID_STR}\xAA\x55" >> $ID_FILE

