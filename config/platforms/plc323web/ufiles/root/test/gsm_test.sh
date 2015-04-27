#gsm_test.sh

# Created on: Sep 27, 2011
#     Author: Mikhail Lodigin, Softerra LLC

# first argument - number of cycles, second argument - device, third argument is pin, 
# fourth argument - address is APN, fifth argument is access number, 
# sixth argument - location to download from

rm -f gsm.res ping.log gsm.log > /dev/null 2>&1

error_counter=0
MAX_ERROR_COUNT=50
PPP_CONNECTION_WAIT=3

#validating input
#check-up ppp interface, if it is not up - it should be set up
ifconfig | grep ppp0 -q
if [ $? -ne 0 ]; then
	killall pppd > /dev/null 2>&1
	echo "setup PPP interface"
	#setup usart
	DEV=$2
	PIN=$3
		
	#stty -F $DEV -parenb -parodd cs8 -hupcl -cstopb cread clocal crtscts \
	#    -ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon \
	#    -ixoff -iuclc -ixany -imaxbel -opost -olcuc -ocrnl onlcr -onocr -onlret \
	#    -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0 -isig -icanon -iexten -echo echoe \
	#    echok -echonl -noflsh -xcase -tostop -echoprt echoctl echoke
	#stty -F $DEV speed 115200
	
	echo -en "ATZ\r" > $DEV
	echo -en "ATZ\r" > $DEV
	echo -en "AT+CPIN=$PIN\r" > $DEV
	/sbin/modprobe ppp > /dev/null 2>&1 
	sleep 3
	
	while [ 1 ]
	do
		#init ppp interface
		/usr/sbin/pppd logfile pppd.log call gprs
		/sbin/ifconfig | grep ppp0 -q
		if [ $? -ne 0 ]; then
			if [ $PPP_CONNECTION_WAIT -ne 0 ]; then
				PPP_CONNECTION_WAIT=`expr $((PPP_CONNECTION_WAIT-1))`
				echo "establishing connection with ISP" > gsm.log
				sleep 1
			else
				echo "unable to establish connection with ISP, see pppd.log" > gsm.log
				#echo "connection error" > gsm.res
				echo "success= 0 loss= $1" > /tmp/gsm.res
				exit 1
			fi
		else
			break
		fi
	done
fi 
# ppp interface is up at this point

# start the test

ping -q -c $1 $6 > ping.log

transmitted_packets=`cat ping.log | awk '/packets/ {print $1}'`
recieved_packets=`cat ping.log | awk '/packets/ {print $4}'`
errors=`expr $((transmitted_packets-recieved_packets))`
success=`expr $((transmitted_packets-errors))`
echo "success= $success loss= $errors" > /tmp/gsm.res
#cat gsm.res