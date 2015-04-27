#!/bin/sh

SCRIPT_DIR=/mnt/ufs/root
ID_FILE=id_file

EEPROM_DIR=/sys/devices/platform/atmel_spi.0/spi0.2
EEPROM_IF=$EEPROM_DIR/eeprom

#echo -n "Making and writing ID..."

# make ID
$SCRIPT_DIR/make_id.sh $SCRIPT_DIR/$ID_FILE

# write ID
dd if=$SCRIPT_DIR/$ID_FILE of=$EEPROM_IF bs=1024 count=1 seek=63 2>/dev/null

# remove file with ID and script which makes it
rm $SCRIPT_DIR/$ID_FILE
rm $SCRIPT_DIR/make_id.sh

#echo "done."
