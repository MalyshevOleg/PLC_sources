#!/bin/sh

# include PIN settings
if [ -f /etc/ppp/peers/$1.wc ]; then
	. /etc/ppp/peers/$1.wc

	if [ "$WC_PIN" != "" ]; then
		if [ "$WC_PIN_WAIT_SEC" == "" ]; then
			WC_PIN_WAIT_SEC=5
		fi
		
		#echo "checking PIN status" > /dev/console
		answer=""
		echo -en "AT+CPIN?\r"

		while [ 1 ]; do
			read -t 2 line
			if [ $? -ne 0 ]; then
				break;
			fi
			answer=$answer$line
		done
	
		#echo -en "answer got:===\n$answer\n===\n" > /dev/console
		if [ "$answer" == "" ]; then
			#echo "failed to get answer at all" > /dev/console
			exit 255
		else
			(echo $answer | grep -q 'SIM PIN')
			if [ $? -eq 0 ]; then
				echo -en "AT+CPIN=$WC_PIN\r"
				#echo "entered PIN" > /dev/console
				sleep $WC_PIN_WAIT_SEC
			fi
		fi
	fi
fi

/usr/sbin/chat -v -f /etc/ppp/peers/$1.chat
