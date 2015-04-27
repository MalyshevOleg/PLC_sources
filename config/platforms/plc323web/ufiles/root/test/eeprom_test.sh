#!/bin/sh

# Args:
# 1 - number of iterations to perform

. ./test_functions

# determine spi interface and eeprom interface
spi_if=`ls -l /sys/module/at25/drivers/spi\:at25/ | grep spi | cut -c58-63`
eeprom_if=/sys/devices/platform/atmel_spi.0/$spi_if/eeprom

eeprom_read_data_file=$test_work_dir/eeprom_read_data
test_file=

# for repeat on error functionality
# max_io_attempts=3

total=$1
success=0
test_iterations=$total
trigger=0
while [ $test_iterations -gt 0 ]; do
	test_iterations=$((test_iterations-1))

	# clean previous data read from eeprom
	rm -f $eeprom_read_data_file
	
	# specify data file for current iteration
	if [ $trigger -eq 0 ]; then
		trigger=1
		test_file=$eeprom_data_file0
	else
		trigger=0
		test_file=$eeprom_data_file1
	fi
	#echo "test_file=$test_file"
		
	#attempts=$max_io_attempts
	#rc=255
	#while [ $rc -ne 0 -a $attempts -gt 0 ]; do
		cat $test_file > $eeprom_if 2>/dev/null &
		curr_pid=$!
		wait_pid_for_n100ms $curr_pid 3
		wait $curr_pid
		rc=$?
		#attempts=$((attempts-1))
	#done
		
	# do not read & compare - these will lead to failure eventually
	if [ $rc -ne 0 ]; then
		#echo "writing to EEPROM failed"
		continue;
	fi

	#attempts=$max_io_attempts
	#rc=255
	#while [ $rc -ne 0 -a $attempts -gt 0 ]; do
		cat $eeprom_if > $eeprom_read_data_file 2>/dev/null &
		curr_pid=$!
		wait_pid_for_n100ms $curr_pid 3
		wait $curr_pid
		rc=$?
		#attempts=$((attempts-1))
	#done
	
	if [ $rc -ne 0 ]; then
		#echo "reading from EEPROM failed"
		continue;
	fi

	# compare
	diff -q $test_file $eeprom_read_data_file 2>&1 > /dev/null
	if [ $? -ne 0 ]; then
		#echo "EEPROM test is failed"
		continue
	fi
		
	success=$((success+1))
done

report_result $success $((total-$success)) $test_work_dir/eeprom.res
#echo "EEPROM test is done: success/loss: $success/$((total-$success))"
