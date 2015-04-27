#----------------------------------------------
# Shell-include
# Common variables for network scripts
#----------------------------------------------

eth_iface="eth0"

file_resolv_conf=/etc/resolv.conf
file_hostname=/etc/HOSTNAME
file_network_conf=/etc/network.conf

dir_runtime=/var/run/network
file_ppp_save_gw=$dir_runtime/ppp_save_gw
file_ppp_save_dns=$dir_runtime/ppp_save_dns

dir_lock=$dir_runtime/lock
lock_usleep=100000
lock_attempts=30

file_ppp_flag=$dir_runtime/ppp-flag

dir_ddns_conf=/etc/ddns
file_ddns_conf=$dir_ddns_conf/ddns.conf
file_ddns_log=

dir_ppp_profiles=/etc/ppp/peers

# UDHCPC handler
script_udhcpc=/etc/network/udhcpc.sh

file_log=/dev/null

# firewall defines
file_firewall_conf=/etc/firewall.conf

chain_input=f_INPUT
chain_forward=f_FORWARD
chain_nat=n_POSTROUTING

#----------------------------------------------
# Executive part
#----------------------------------------------

# make sure runtime dir is present
mkdir -p $dir_runtime

# Params
# 1 - item
# 2 - list as a signgle param
check_item_in_list()
{
	for i in $2; do
		if [ "$1" == "$i" ]; then
			return 1
		fi
	done
	return 0
}

# Params:
# 1 - resolv.conf file to update (actual resolv.conf or its ppp-backup)
# 2 - domain name (search) as single param
# 3 - list of DNS servers as 1 param
check_dns_need_update()
{
	_resolv_conf=$1
	_search=$2
	_new_list=$3
	_cur_search=
	_cur_list=

	# create list of nameservers from resolv.conf
	if [ ! -f ${_resolv_conf} ]; then
		echo "...${_resolv_conf} does not exist"
		return 1
	fi

	while read line; do
		set $line > /dev/null
		if [ "$1" == "search" -a "$2" != "" ]; then
			_cur_search="$2"
		fi
		if [ "$1" == "nameserver" -a "$2" != "" ]; then
			_cur_list="$2 ${_cur_list}"
		fi
	done < ${_resolv_conf}

	if [ "${_search}" != "${_cur_search}" ]; then
		echo "...at least 'search' has to be updated"
		return 1
	fi

	for dns in ${_new_list}; do
		check_item_in_list $dns "${_cur_list}"
		if [ $? -eq 0 ]; then
			echo "...at least one of new addr $dns is not in current list"
			return 1
		fi
	done

	for dns in ${_cur_list}; do
		check_item_in_list $dns "${_new_list}"
		if [ $? -eq 0 ]; then
			echo "...at least one of current addr $dns is not in new list"
			return 1
		fi
	done

	return 0
}

# Params:
# 1 - resolv.conf file to update (actual resolv.conf or its ppp-backup)
# 2 - domain name (search) as single param
# 3,... - list of DNS servers as 1 param or separate params
update_dns()
{
	_dns_list=
	_search=
	_resolv_conf=$1
	shift
	_search=$1
	shift

	# build list of servers
	while [ $# -gt 0 ]; do
		_dns_list="$1 ${_dns_list}"
		shift
	done

	check_dns_need_update ${_resolv_conf} "${_search}" "${_dns_list}"
	if [ $? -eq 0 ]; then
		echo "No need to update DNS"
		return
	fi

	echo "Creating ${_resolv_conf}"
	echo -n > ${_resolv_conf}

	if [ -n "${_search}" ]; then
		echo "search ${_search}" >> ${_resolv_conf}
	fi

	for dns in ${_dns_list}; do
		echo "nameserver $dns" >> ${_resolv_conf}
	done
	sync
}

# return 0 - sucess, 1 - failed
network_lock()
{
	attempts=$lock_attempts

	while [ $attempts -gt 0 ]; do
		mkdir $dir_lock

		if [ $? -eq 0 ]; then
			return 0
		fi

		usleep $lock_usleep
		attempts=$((attempts - 1))
	done

	return 1
}

network_unlock()
{
	rmdir $dir_lock
}

# params $1 - interface or if not specified - all default gateways
clean_def_gateways()
{
	_iface=$1
	#ifconfig $1 0.0.0.0
	# Codesys unregisters interface if this command done

	if [ "${_iface}" == "" ]; then
		iftext=ALL
	else
		iftext=${_iface}
	fi

	if [ -f $file_ppp_flag ]; then
		echo "Removing saved by PPP default gateways: $iftext"
		if [ "${_iface}" == "" ]; then
			echo -n > $file_ppp_save_gw
		else
			_tmp_gw="/tmp/tmp-gw-$$"
			echo -n > ${_tmp_gw}
			while read line; do
				set $line > /dev/null
				if [ "${_iface}" != "$3" ]; then
					echo $line >> ${_tmp_gw}
				fi
			done < $file_ppp_save_gw
			cat ${_tmp_gw} > $file_ppp_save_gw
			rm ${_tmp_gw}
		fi
	else
		echo "Removing real default gateways: $iftext"
		route -n | grep UG | awk '{print $2 " " $8;}' | \
			while read line; do
				set $line > /dev/null
				if [ "${_iface}" == "" -o "${_iface}" == "$2" ]; then
					route del default gw $1 dev $2
				fi
			done
	fi
}

check_ddns_is_running()
{
	ps | grep "inadyn" | grep -q -v grep
}

firewall() {
	[ -x /etc/rc.fw ] && /etc/rc.fw $*
}

