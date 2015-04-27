# plc323_testbench
#
# Created on: Jun 29, 2011
#     Author: Mikhail Lodigin

# need for setting up test data files and veriables
. ./test_functions

# local functions

# semaphores for each test

init_tests()
{
	for i in $(seq 1 11); do
		if [ $i -lt 10 ]; then
			_var=test_0$i
		else
			_var=test_$i
		fi
		eval "$_var=0"
	done
	
	rm -f /tmp/*.res > /dev/null 2>&1
}

# Args:
# 1 - test ID
# 2 - run string
run_test()
{
	var=test_$1
	eval val=\$$var
	if [ $val -eq 1 ]; then
		# test is running, do nothing
		return 255
	fi
	
	# run the test (first, set the semaphore)
	eval "$var=1"
	eval $2
	return 0
}

# Process a report file created by a test, 
# accumulate counters in the specified variables
# Args:
# 1 - test ID
# 2 - .res file of the test
# 3 - success var name
# 4 - loss var name
# 5 - wait - wait or not for result file
calculate_results()
{
	_id=$1
	_file=$2
	_sname=$3
	_lname=$4
	_wait=$5

	while [ ! -s "$_file" ]; do
		#echo "!!!" $1
		if [ $_wait -ne 0 ]; then
			sleep 1
		else
			# will success next time..
			return 0
		fi
	done

	# - report file exists and has size > 0
	# - report file SHOULD contain a string "success= %d loss= %d\n"
	# - writing of this string is very quick, 
	#   so check that the file has correct format within 1 second
	try_count=10
	while [ 1 ]; do
		grep -q 'success= [0-9][0-9]* *loss= [0-9][0-9]*$' $_file
		if [ $? -eq 0 ]; then
			break
		fi
		
		try_count=$((try_count-1))
		
		if [ $try_count -gt 0 ]; then
			usleep 100000
		else
			# return error
			return 255
		fi
	done
	
	# so file is good and assumed to be complete
	
	# get number of successes and losses
	cur_success=`cat $_file | awk '{print $2}'`
	cur_errors=`cat $_file | awk '{print $4}'`
	#echo $cur_success
	#echo $cur_errors

	tmp=\$"$_sname"
	tmp=`eval "expr $tmp + $cur_success"`
	eval "$_sname=$tmp"
	
	tmp=\$"$_lname"
	tmp=`eval "expr $tmp + $cur_errors"`
	eval "$_lname=$tmp" 

	# remove .res file accounted
	rm -f $_file

	# merk test done
	var=test_$_id
	eval "$var=0"

	return 0
}

# Read user's input. 
# The input value is expected to be numeric and belong to the range specified.
# If the value is valid it is assigned to the variable with specified name,
# otherwise the sepecified error message is printed.
# The result value is a 2-digit string (prepended by 0 as need)
# args:
# 1 - variable name
# 2 - higher margin
# 3 - lower margin
# 4 - message printed on invalid input
data_input_filtering()
{
	read var
	
	while [ 1 ]; do
		while [ ! `echo $var | grep -E "^[0-9]+$"` ]; do
			echo "Input was non numeric, enter again"
			read -r var
		done
		
		if [ $var -gt $2 -o $var -lt $3 ]; then
			echo $4
			read -r var
		else
			break
		fi
	done
	
	if [ $var -lt 10 ]; then
		eval "$1=0$var"
	else
		eval "$1=$var"
	fi 
}

# Args:
# 1 - port
# 2 - speed
setup_gsm_port()
{
	_port=$1
	_speed=$2

	stty -F $_port $_speed -parenb -parodd cs8 -hupcl -cstopb cread clocal crtscts \
		-ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon \
		-ixoff -iuclc -ixany -imaxbel -opost -olcuc -ocrnl onlcr -onocr -onlret \
		-ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0 -isig -icanon -iexten -echo echoe \
		echok -echonl -noflsh -xcase -tostop -echoprt echoctl echoke > /dev/null 2>&1
	
	echo "Modem port $_port set up for $_speed"
}

# args:
# 1 - GPIO num of PWR_GSM (VBAT)
# 2 - GPIO num of ON_GSM (PWR_KEY)
gsm_off()
{
	# turn VBAT off
	echo 1 > /sys/class/gpio/gpio$1/value
	# release PWR_KEY
	echo 0 > /sys/class/gpio/gpio$2/value
}

# args:
# 1 - GPIO num of PWR_GSM (VBAT)
# 2 - GPIO num of ON_GSM (PWR_KEY)
gsm_on()
{
	# turn VBAT on
	echo 0 > /sys/class/gpio/gpio$1/value
	sleep 1
	# trigger power by PWRKEY
	echo 1 > /sys/class/gpio/gpio$2/value
	sleep 1
	echo 0 > /sys/class/gpio/gpio$2/value
}

# Args:
# 1 - port
# PB2 (gpio66) - ON_GSM -> inverted PWR_KEY
# PB6 (gpio70) - PWR_GSM -> inverted VBAT
# PB8 (gpio72) - STATUS_GSM -> STATUS
# - Assume GSM is already set up if STATUS GPIO interface is present
# - As result, set external flag $gsm_is_not_operational
start_gsm()
{
	_on=66
	_pwr=70
	_status=72
	
	if [ ! -e /sys/class/gpio/gpio$_status/value ]; then
		# activate GPIO interface
		echo $_status > /sys/class/gpio/export
		echo $_on > /sys/class/gpio/export
		echo $_pwr > /sys/class/gpio/export

		# set lines' mode and initial state
		echo "out" > /sys/class/gpio/gpio$_pwr/direction
		echo "out" > /sys/class/gpio/gpio$_on/direction
		echo "in" > /sys/class/gpio/gpio$_status/direction
		gsm_off $_pwr $_on
		sleep 1
		gsm_on $_pwr $_on
		sleep 1
		#echo "INIT GSM STATUS="`cat /sys/class/gpio/gpio$_status/value`
	fi

	_attempts=10
	_ma_file=/tmp/modem_answer
	while [ 1 ]; do
		_status_val=`cat /sys/class/gpio/gpio$_status/value`
		if [ $_status_val -eq 1 ]; then
			# try requesting modem
			# - cleanup
			read -t 1 _answer < $1
			
			# read from modem
			cat $1 > $_ma_file &
			_ma_pid=$!
			usleep 100000
			echo -en "ATZ\r" > $1
			usleep 100000
			echo -en "ATZ\r" > $1
			usleep 100000
			
			kill $_ma_pid
			wait $_ma_pid
			
			#echo "MODEM answer: '`cat $_ma_file`'"
			grep "OK" -q $_ma_file
			if [ $? -eq 0 ]; then
				break
			fi
		fi
		
		_attempts=$((_attempts-1))
		if [ $_attempts -le 0 ]; then
			echo "Modem setup failure"
			gsm_is_not_operational=1
			break
		fi
		
		# attempt to restart modem
		gsm_off $_pwr $_on
		sleep 1
		gsm_on $_pwr $_on
		sleep 1
	done

	gsm_status=$_status_val
	if [ $gsm_is_not_operational -eq 1 ]; then
		echo "GSM is NOT operational"
	else
		echo "GSM is operational"
	fi
}

. ./test_config.cfg

ALL_MENU=12
TEST_RESULT=plc323_test_result.txt
eeprom_success=0
eeprom_loss=0
usb_success=0
usb_loss=0
sd_success=0
sd_loss=0
gpio_sucesss=0
gpio_loss=0
rs485_success=0
rs485_loss=0
rs232_success=0
rs232_loss=0
debug_success=0
debug_loss=0
can_success=0
can_loss=0
discrete_success=0
discrete_loss=0
gsm_success=0
gsm_loss=0
security_success=0
security_loss=0
eeprom_pid=0
usb_pid=0
sd_pid=0
gpio_pid=0
rs485_pid=0
can_pid=0
discrete_pid=0
gsm_pid=0
rs232_pid=0
debug_pid=0
discrete_pid=0
security_pid=0

echo 0 > /proc/sys/kernel/printk
PATH=/sbin/:$PATH
/sbin/modprobe at25

#sanity check

#UART interface check
#uart_number=0
#uart_list=`ls /dev/ttyS*`
#for i in $uart_list
#do
#	if [ $i != "/dev/ttyS0" -a $i != "/dev/ttyS2" ]; then
#		uart_number=`expr $((uart_number+1))`
#	fi
#done
#discrete input/output check
#discrete input/output configuration is dependent on DIP switch.
#check DIP switch SA1.3 (signal SEL_IO2, pin PC2)
if [ ! -d /sys/class/gpio/gpio98 ]; then
	echo 98 > /sys/class/gpio/export
	sleep 1
fi
switchSA13=`cat /sys/class/gpio/gpio98/value`
case $switchSA13 in
1)
	#discrete configuration 1
	echo "TEST TEST TEST GPIO CONFIGURATION 1";
	;;
	
0)
	#discrete configuration 2
	echo "TEST TEST TEST GPIO CONFIGURATION 2";
	;;
esac

# GSM
gsm_is_not_operational=0
/sbin/ifconfig ppp0 2>/dev/null |grep RUNNING -q
if [ $? -ne 0 ]; then
	setup_gsm_port /dev/ttyS2 115200
	start_gsm /dev/ttyS2
fi

# set up test data files
setup_eeprom_test_data
setup_serial_test_data 256

# setup access point and access phone
sed -i -e '/CGDCONT/s;^\([^,]\+\),\([^,]\+\),\(.*\)$;\1,\2,\\042'$ACCESS_POINT_GPRS'\\042";' /etc/ppp/gprs.chat
sed -i -e '/ATD/s;ATD\(.*\)$;ATD'$ACCESS_NUMBER';' -e '/TIMEOUT/s/ \(.*\)$/ '$GSM_CONNECTION_TIMEOUT'/' /etc/ppp/gprs.chat
sed -i -e '/persist/s;^per;#per;' /etc/ppp/options
sed -i -e '/chat/s/chat -v/chat -t '$GSM_RECONNECT_TIMEOUT' -v/' /etc/ppp/peers/gprs

# setup CAN 
ip link set can0 type can bitrate $CAN_SPEED
ip link set can1 type can bitrate $CAN_SPEED

# can interface up
ip link set can0 up > /dev/null 2>&1
ip link set can1 up > /dev/null 2>&1
# start CAN echo server
./test_can -s -d can0 -e &
can_pid=$!

read -r -p "Do you want to set time? ( press Y if yes, or any other key otherwise ) " test_mode

if [ "$test_mode" == "Y" -o "$test_mode" == "y" ]; then
	#setup time
	echo "Please, enter the year"
	data_input_filtering YEAR 2110 2011 "Utility strongly believes that year you've entered is incorrect, please enter valid year"

	echo "Please, enter the month (valid input is from 1 to 12)"
	data_input_filtering MONTH 12 1 "You've entered invalid month, please re-enter month"

	echo "Please, enter date"
	data_input_filtering DATE 31 1 "You've entered invalid date, please re-enter date"

	echo "Please, enter hour"
	data_input_filtering HOUR 23 0 "You've entered invalid hour, Please re-enter hour"

	echo "Please, enter minute"
	data_input_filtering MINUTE 59 0 "You've entered invalid minute, Please re-enter minute" 

	date -s $YEAR$MONTH$DATE$HOUR$MINUTE > /dev/null 2>&1
	hwclock -w
	#end of time setup
fi

# versions
version_linux=0x`cat /proc/cpuinfo | grep "Serial" | cut -d ":" -f 2 | cut -d " " -f 2`
version_linux=$((version_linux+0))
version_fs=`grep "OWEN-" /etc/RELEASE | cut -d "-" -f 3`

# interactive menu

while [ 1 ]; do
	clear

	echo " PLC323 Test Suite"
	echo " Linux kernel version: $version_linux"
	echo " Filesystem version: $version_fs"
	echo ""
	echo " #	Test Name:"
	echo " "
	echo " 1.	EEPROM"
	echo " 2.	USB device/host"
	echo " 3.	SD/MMC"
	echo " 4.	GPIO"
	echo " 5.	RS485"
	echo " 6.	CAN"
	echo " 7.	DISCRETE"
	if [ $gsm_is_not_operational -eq 1 ]; then
		echo " 8.	GSM is not operational after 10 setup attempts (status=$gsm_status)"
	else
		echo " 8.	GSM"
	fi
	echo " 9.	SECURITY"
	echo " 10	RS232"
	echo -n " 11	DEBUG"
	if [ ! -c /dev/ttyS5 ]; then
		echo " is disabled (console enabled instead)"
	else
		echo ""
	fi
	echo " 12.	ALL"
	echo " ------------"
	echo " 13.	EXIT"
	echo "-------------------------------------------------"
	echo ""

	echo -n "Select the test: "
	data_input_filtering test_choice `expr $ALL_MENU + 1` 1 "Invalid choice made, please re-enter"

	if [ $test_choice -eq "11" -a ! -c /dev/ttyS5 ]; then
		echo "The test choice ignored - debug is disabled"
		sleep 1
		continue
	fi

	if [ $test_choice -eq `expr $ALL_MENU + 1` ]; then
		echo "Thank you for choosing Softerra's software products, bye-bye"
		killall test_can > /dev/null 2>&1
		ip link set can0 down
		ip link set can1 down
		exit
	fi

	while [ 1 ]; do
		read -r -p "Select test mode: one-shot(O) or cyclic(C): " test_mode
		
		if [ "$test_mode" != "O" -a "$test_mode" != "o" -a "$test_mode" != "C" -a "$test_mode" != "c" ]; then
			echo "Sorry, but your input is invalid, please re-enter your choice"
			continue
		else
			break
		fi
	done
	
	# init semaphores, remove result files
	init_tests
	
	# back to waiting all results before running next iteration
	#if [ $test_mode == "O" -o $test_mode == "o" ]; then
		wait_result=1
	#else
	#	wait_result=0
	#fi
	
	#GPIO test is special. it is either executed once or till 'S' pressed in cyclic execution.
	if [ $test_choice == "04" -o $test_choice == $ALL_MENU ]; then
		if [ $test_mode == "o" -o $test_mode == "O" ]; then
			run_test "04" "./gpio_test.sh 1 &"
		else
			run_test "04" "./gpio_test.sh &"
		fi
	fi
	
	setup_serial=1
	while [ 1 ]; do
		#start separate tests
		
		if [ $test_choice == "05" -o $test_choice == $ALL_MENU ]; then
			#if [ $rs485_pid -eq 0 ]; then
				run_test "05" "./serial_test.sh $RS485_CYCLES $RS485_SPEED 485 $setup_serial /dev/ttyS3 /dev/ttyS4 &"
				rs485_pid=$!
				#echo "11"
			#fi
		fi
		
		if [ $test_choice == "06" -o $test_choice == $ALL_MENU ]; then
			run_test "06" "./test_can -s -r /tmp/can.res -d can1 $CAN_CYCLES \"S 123 1 ab\" \"E 12345678 0\" &"
		fi
		
		#if [ $test_choice == "02" -o $test_choice == $ALL_MENU ]; then
		#./usb_test $USB_CYCLES &
		#fi
		
		if [ $test_choice == "03" -o $test_choice == $ALL_MENU ]; then
			run_test "03" "./sd_test $SD_CYCLES &"
			sd_pid=$!
		fi
		#echo "12"
		if [ $test_choice == "01" -o $test_choice == $ALL_MENU ]; then
			run_test "01" "./eeprom_test.sh $EEPROM_CYCLES &"
			eeprom_pid=$!
		fi
		#echo "13"
		if [ $test_choice == "07" -o $test_choice == $ALL_MENU ]; then
			run_test "07" "./discrete_test 8 1 $DISCRETE_INPUT_LIST 0 $DISCRETE_OUTPUT_LIST &"
			discrete_pid=$!
		fi
		if [ $gsm_is_not_operational -ne 1 ]; then
			if [ $test_choice == "08" -o $test_choice == $ALL_MENU ]; then
				run_test "08" "./gsm_test.sh $GSM_CYCLES /dev/ttyS2 1111 www.ab.kyivstar.net *99***1# $PING_ADDRESS &"
				gsm_pid=$!
			fi
		fi 
		
		if [ $test_choice == "09" -o $test_choice == $ALL_MENU ]; then
			run_test "09" "./security_test -D /dev/spidev0.5 &"
			security_pid=$!
		fi
		
		if [ $test_choice == "10" -o $test_choice == $ALL_MENU ]; then
			run_test "10" "./serial_test.sh $RS232_CYCLES $RS232_SPEED 232 $setup_serial /dev/ttyS1 &"
			rs232_pid=$!
		fi
		
		if [ -c /dev/ttyS5 ]; then
			if [ $test_choice == "11" -o $test_choice == $ALL_MENU ]; then
				run_test "11" "./serial_test.sh $RS232_CYCLES $RS232_SPEED 232 $setup_serial /dev/ttyS5 &"
				debug_pid=$!
			fi
		fi

		#check results availability and present them
		
		# wait a bit - waiting while reading for 'S'
		#usleep 200000
		
		#echo "14"
		if [ $test_choice == "05" -o $test_choice == $ALL_MENU ]; then
			calculate_results "05" "/tmp/rs485.res" rs485_success rs485_loss $wait_result
		fi
		#echo "15"
		if [ $test_choice == "06" -o $test_choice == $ALL_MENU ]; then
			calculate_results "06" "/tmp/can.res" can_success can_loss $wait_result
		fi
		#echo "16"
#		if [ $test_choice == "02" -o $test_choice == $ALL_MENU ]; then
#			calculate_results "02" "/tmp/usb.res" usb_success usb_loss $wait_result
#		fi
		#echo "17"
		if [ $test_choice == "03" -o $test_choice == $ALL_MENU ]; then
			calculate_results "03" "/tmp/sd.res" sd_success sd_loss $wait_result
		fi
		#echo "18"
		if [ $test_choice == "01" -o $test_choice == $ALL_MENU ]; then
			calculate_results "01" "/tmp/eeprom.res" eeprom_success eeprom_loss $wait_result
		fi
		#echo "19"
		if [ $test_choice == "07" -o $test_choice == $ALL_MENU ]; then
			calculate_results "07" "/tmp/discrete.res" discrete_success discrete_loss $wait_result
		fi
		
		if [ $gsm_is_not_operational -ne 1 ]; then
			if [ $test_choice == "08" -o $test_choice == $ALL_MENU ]; then
				calculate_results "08" "/tmp/gsm.res" gsm_success gsm_loss $wait_result
			fi
		fi
		#echo "20"
		if [ $test_choice == "09" -o $test_choice == $ALL_MENU ]; then
			calculate_results "09" "/tmp/security.res" security_success security_loss $wait_result
		fi

		if [ $test_choice == "10" -o $test_choice == $ALL_MENU ]; then
			calculate_results "10" "/tmp/rs232_1.res" rs232_success rs232_loss $wait_result
		fi
		
		if [ -c /dev/ttyS5 ]; then
			if [ $test_choice == "11" -o $test_choice == $ALL_MENU ]; then
				calculate_results "11" "/tmp/rs232_5.res" debug_success debug_loss $wait_result
			fi
		fi
		
		# do not setup serial on th emext cycles
		setup_serial=0
		
		clear
		#present results
		echo "=========================================================="
		echo "||Peripheral name	||	Success	||	Loss	||"
		echo "||	RS485		||	"$rs485_success"	||	"$rs485_loss"	||"
		echo "||	RS232		||	"$rs232_success"	||	"$rs232_loss"	||"
		echo "||	DEBUG		||	"$debug_success"	||	"$debug_loss"	||"
		echo "||	CAN		||	"$can_success"	||	"$can_loss"	||"
		echo "||	USB		||	"$usb_success"	||	"$usb_loss"	||"
		echo "||	SD		||	"$sd_success"	||	"$sd_loss"	||"
		echo "||	EEPROM		||	"$eeprom_success"	||	"$eeprom_loss"	||"
		echo "||	DISCRETE	||	"$discrete_success"	||	"$discrete_loss"	||"
		if [ $gsm_is_not_operational -ne 1 ]; then
			echo "||	GSM		||	"$gsm_success"	||	"$gsm_loss"	||"
		fi
		echo "||	SECURITY	||	"$security_success"	||	"$security_loss"	||"
		echo "    Timestamp: " `hwclock`
		echo "=========================================================="

		if [ $test_mode == "o" -o $test_mode == "O" ]; then
			read -n 1 -p "Press any key to enter menu"
			#killing backgound jobs exept can server
			JOBS=`jobs -p`
			for i in $JOBS; do
				if [ $i -ne $can_pid ]; then
					kill $i > /dev/null 2>&1
				fi
			done
			break
		else
			echo "==== Press S to stop ===="
			input=
			read -s -n 1 -t 1 input
			if [ "$input" == "s" -o "$input" == "S" ]; then
				#killing backgound jobs exept can server
				JOBS=`jobs -p`
				for i in $JOBS; do
					if [ $i -ne $can_pid ]; then
						kill $i > /dev/null 2>&1
					fi
				done
				break
			fi
		fi
	done
done
