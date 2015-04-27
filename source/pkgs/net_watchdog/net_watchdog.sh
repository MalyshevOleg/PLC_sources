#!/bin/sh

source /etc/network/common.sh

                




logger() {
  [ -n "$USE_SYSLOG" ] && {
    /usr/bin/logger $*
  }
}

[ "$1" = "-reload" ] && {
  daemon_pid=`ps | grep $0 | grep -v grep | grep -v "\-reload" | awk '{print $1}'`
  [ -n "$daemon_pid" ] && kill -HUP $daemon_pid
  exit 0
}

[ "$1" = "-stop" ] && {
  daemon_pid=`ps | grep $0 | grep -v grep | grep -v "\-stop" | awk '{print $1}'`
  [ -n "$daemon_pid" ] && kill $daemon_pid
  exit 0
}

reload() {
  fail_cnt=0
  period_s=0
  [ -f /etc/net_watchdog.conf ] && source /etc/net_watchdog.conf
  [ -f $file_network_conf ] && source $file_network_conf
  [ -z "$TIMEOUT" ] && TIMEOUT=20
  [ -z "$FAIL_COUNT" ] && FAIL_COUNT=3
  [ -n "$child_pid" ] && kill $child_pid
  [ -n "$PERIOD" ] && period_s=$(($PERIOD*60))
  do_reload=1
}

stop() {
  [ -n "$child_pid" ] && kill $child_pid
  exit 0
}

schedule() {
  sched_next=`date +%s`
  sched_next=$(($sched_next+$period_s))
}

pppd_start() {
    /etc/rc.net startppp
}

trap reload SIGHUP
trap stop SIGTERM

reload

schedule

while true; do
  if [ $period_s -gt 0 ]; then
    unset do_reload
    sleep_time=$(($sched_next-`date +%s`))
    [ $sleep_time -gt 0 ] && {
      sleep $sleep_time &
      child_pid=$!
      wait $child_pid
      unset child_pid
    }
    schedule
    [ -n "$do_reload" ] && {
      logger -p daemon.notice -s "net_watchdog:" "reloaded config: $PERIOD,$HOSTS,$TIMEOUT,$FAIL_COUNT,$GPRS_AUTO"
      continue
    }

    fail="yes"

    save_ifs=$IFS
    IFS=";" 
    for host in $HOSTS; do
      ping -s 3 -w $TIMEOUT -c 1 $host >/dev/null 2>&1 && { unset fail; break; }
    done
    IFS=$save_ifs

    if [ "$fail" = "yes" ]; then
      fail_cnt=$(($fail_cnt+1))
      [ "$fail_cnt" = "$FAIL_COUNT" ] && {
        # detect active connection, STORE in ppp_conn, interface name in ppp_if
        unset ppp_conn
        for cn in $dir_runtime/*.cn; do
          ppp_conn=`grep -s '\.gprs$' "$cn" | sed 's,\.gprs$,,'`
          [ -n "$ppp_conn" ] && { 
            ppp_if=`echo "$cn" | sed 's,^.*/\(.*\)\.cn,\1,'`
            ppp_pid=`cat "/var/run/${ppp_if}.pid"`
            kill $ppp_pid
            while [ -n "`ps | grep "^\s*$ppp_pid\s.*pppd"`" ]; do sleep 1; done
            break
          }
        done
        ppp_state="fail"
        [ -z "$ppp_conn" -a -n "$GPRS_AUTO" -a -f "/etc/ppp/peers/${GPRS_AUTO}.gprs" ] && ppp_conn=$GPRS_AUTO
        if [ -n "$ppp_conn" ]; then
          logger -p daemon.notice -s "net_watchdog:" "no answer from hosts, restarting ppp ${ppp_conn}.gprs"
          pppd_start $ppp_conn
          [ -n "$ppp_state" ] && pppd_start $ppp_conn
        else
          logger -p daemon.notice -s net_watchdog "no answer from hosts"
        fi
        [ -z "$ppp_state" -a -x /usr/bin/net_ids.sh ] && /usr/bin/net_ids.sh -reload
        fail_cnt=0
      }
    else
      fail_cnt=0
    fi
  else 
    sleep 3600 &
    child_pid=$!
    wait $child_pid
    unset child_pid
    schedule
  fi
done
