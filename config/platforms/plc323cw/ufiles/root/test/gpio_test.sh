#gpio_test.sh
# GPIO testing script
# Created on: Feb 8, 2011
#     Author: Mikhail Lodigin, Softerra LLC
# based on test scripts plc_tests

#turning on GSM. check if it has been turned on already 
if [ ! -e /sys/class/gpio/gpio86/value ]; then

	#signals G0..G2 (PB22, PB27, PD24), RELE1...RELE4 (PD6, PD18, PD21, PD22) outputs
	echo 86 > /sys/class/gpio/export
	echo 91 > /sys/class/gpio/export
	echo 152 > /sys/class/gpio/export
	echo 134 > /sys/class/gpio/export
	echo 146 > /sys/class/gpio/export
	echo 149 > /sys/class/gpio/export
	echo 150 > /sys/class/gpio/export
	sleep 1
	echo "out" > /sys/class/gpio/gpio86/direction
	echo "out" > /sys/class/gpio/gpio91/direction
	echo "out" > /sys/class/gpio/gpio152/direction
	echo "out" > /sys/class/gpio/gpio134/direction
	echo "out" > /sys/class/gpio/gpio146/direction
	echo "out" > /sys/class/gpio/gpio149/direction
	echo "out" > /sys/class/gpio/gpio150/direction
	sleep 1
	echo 0 > /sys/class/gpio/gpio86/value
	echo 0 > /sys/class/gpio/gpio91/value
	echo 0 > /sys/class/gpio/gpio152/value
	echo 0 > /sys/class/gpio/gpio134/value
	echo 0 > /sys/class/gpio/gpio146/value
	echo 0 > /sys/class/gpio/gpio149/value
	echo 0 > /sys/class/gpio/gpio150/value
fi

while [ 1 ] 
do

gpio_status=`cat /sys/class/gpio/gpio86/value`

if [ $gpio_status -eq 1 ]; then
		echo 0 > /sys/class/gpio/gpio86/value
	echo 0 > /sys/class/gpio/gpio91/value
	echo 0 > /sys/class/gpio/gpio152/value
	echo 0 > /sys/class/gpio/gpio134/value
	echo 0 > /sys/class/gpio/gpio146/value
	echo 0 > /sys/class/gpio/gpio149/value
	echo 0 > /sys/class/gpio/gpio150/value
else
	echo 1 > /sys/class/gpio/gpio86/value
	echo 1 > /sys/class/gpio/gpio91/value
	echo 1 > /sys/class/gpio/gpio152/value
	echo 1 > /sys/class/gpio/gpio134/value
	echo 1 > /sys/class/gpio/gpio146/value
	echo 1 > /sys/class/gpio/gpio149/value
	echo 1 > /sys/class/gpio/gpio150/value
fi

#if argument exist - test executed only once
if [ ! -e $1 ]; then
	exit
fi
sleep 1

done