#!/bin/sh

# Args:
# 1 - number of cycles
# 2 - speed
# 3 - IF type: 232 or 485
# 4 - IF setup flag: 1 - set up, 0 - do not set up
# 5 - device1
# 6 - device2 (optional)
#
# * If only device1 is specified, expect arg4=232 (RS232) and RX connected to TX, 
# so read from the device and write to it, then verify result
# * If both devices are specified, then arg4 may be 232 or 485: assume both ports are connected,
# so read from device 1 and write to device 2, check; read from device 2 and write to device 1, check.
#
# Ports configuration is done according to arg4

# Ensure that test file exists

. ./test_functions

total=$1
port_speed=$2
if_type=$3
if_setup=$4
port_in=$5
port_out=$6

# check test type args
if [ $if_type -ne 232 -a $if_type -ne 485 ]; then
	echo "type should be 232 or 485"
	exit 1
fi
if [ $if_type -eq 485 -a "$port_out" == "" ]; then
	echo "RS485 requires two interfaces"
	exit 1
fi

# setup ports
single_port=0
port_list=$port_in
if [ "$port_out" == "" ]; then
	single_port=1
	port_out=$port_in
else
	port_list="$port_list $port_out"
fi

# set up ports if requested
if [ $if_setup -ne 0 ]; then
	#echo "SETUP ports: $if_setup - $port_list"
	for port in $port_list; do
		stty -F $port $port_speed -parenb -parodd cs8 -hupcl -cstopb cread clocal -crtscts \
		-ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon -ixoff -iuclc -ixany \
		-imaxbel -iutf8 \
		-opost -olcuc -ocrnl -onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0 \
		-isig -icanon -iexten -echo -echoe -echok -echonl -noflsh -xcase -tostop -echoprt -echoctl -echoke

		# no switching RS232/485 on PLC323
	done
fi

# setup testing vars
file_out=$serial_data_file

if [ $single_port -ne 0 ]; then
	# determine port interface index
	if_index=`echo $port_in | cut -d "S" -f 2`
	file_res=$test_work_dir/rs${if_type}_${if_index}.res
	file_in=$test_work_dir/rs${if_type}_${if_index}_in.test
else
	file_res=$test_work_dir/rs${if_type}.res
	file_in=$test_work_dir/rs${if_type}_in.test
fi

# file size / speed = estimated time for transfer
file_out_size=`stat -t $file_out | awk '{print $2}'`
transfer_time_n100ms=$((file_out_size*8*10/$port_speed))
#echo "estimated transfer time (n*100ms)=$transfer_time_n100ms"
if [ $transfer_time_n100ms -eq 0 ]; then
	transfer_time_n100ms=1
fi

# args:
# 1 - port_in
# 2 - port out
# 
single_transfer()
{
	_port_in=$1
	_port_out=$2

	# clean up from previous iteration
	rm -f $file_in

	cat $_port_in > $file_in &
	_pid_in=$!
	usleep 100000
	cat $file_out > $_port_out &
	_pid_out=$!
	
	# give for whole transfer no more than time for transfer + 2 secs (should be conformed with test file size)
	wait_file_size_for_n100ms $file_in $file_out_size $((transfer_time_n100ms + 20))
	kill $_pid_out > /dev/null 2>&1
	kill $_pid_in > /dev/null 2>&1

	wait $_pid_out
	wait $_pid_in
	
	# do not test result codes of the operation, just check result file
	diff -q $file_out $file_in 2>&1 > /dev/null
	rc=$?
	#echo "fin=$file_in, fout=$file_out, pin=$_port_in, pout=$_port_out, diff rc=$rc"
	return $rc
}

# main loop: 1 port - one transfer per iteration, 2 ports - 2 transfers per iteration
success=0
test_iterations=$total
while [ $test_iterations -gt 0 ]; do
	test_iterations=$((test_iterations-1))
	
	single_transfer $port_in $port_out
	if [ $? -ne 0 ]; then
		#echo "Serial($4) test $port_out -> $port_in failed"
		continue
	fi
	
	if [ $single_port -eq 0 ]; then
		single_transfer $port_out $port_in
		if [ $? -ne 0 ]; then
			#echo "Serial($4) test $port_in -> $port_out failed"
			continue
		fi
	fi
	
	success=$((success+1))
done

report_result $success $((total-$success)) $file_res
#echo "Serial($4) test is done: success/loss: $success/$((total-$success))"
