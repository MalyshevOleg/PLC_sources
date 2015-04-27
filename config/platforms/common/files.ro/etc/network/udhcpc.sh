#!/bin/sh

. /etc/network/common.sh

#echo "------ UDHCPC handler -------" >> $file_log
#echo "args: '$*'" >> $file_log
#set >> $file_log
#echo "---------------------------------" >> $file_log

_dhcp_netmask=""
_dhcp_broadcast="broadcast +"
[ -n "$subnet" ] && _dhcp_netmask="netmask $subnet"
[ -n "$broadcast" ] && _dhcp_broadcast="broadcast $broadcast"

case "$1" in
	deconfig)
		echo "Setting IP address 0.0.0.0 on $interface"

		#ifconfig $interface 0.0.0.0
		
		# For now, partially ignore the request:
		# leave interface with assigned IP but remove default gateways
		# When Codesys is fixed to accept 0.0.0.0 use the origin deconfig action - 
		# assign 0.0.0.0 to the interface
		clean_def_gateways $interface
		;;

	renew|bound)
		echo "Setting IP address $ip on $interface"
		ifconfig $interface $ip ${_dhcp_netmask} ${_dhcp_broadcast} up
		
		# processing default gateways
		if [ -n "$router" ]; then
			metric=0

			network_lock

			clean_def_gateways $interface
			if [ -f $file_ppp_flag ]; then
				for r in $router; do
					echo "Adding default gw $r to saved by PPP"
					echo $r " " $((metric++)) " " $interface >> $file_ppp_save_gw
				done
			else
				for r in $router; do
					echo "Adding real default gw $r"
					route add default gw $r metric $((metric++)) dev $interface
				done
			fi

			network_unlock
		fi
		
		# processing resolver config
		if [ -n "$dns" -o -n "$domain" ]; then
			network_lock
			if [ -f $file_ppp_flag ]; then
				update_dns $file_ppp_save_dns "$domain" $dns
			else
				update_dns $file_resolv_conf "$domain" $dns
			fi
			network_unlock
		fi
		;;

	*)
		#echo "Unknown option" >> $file_log
		exit 1
	;;
esac

exit 0
