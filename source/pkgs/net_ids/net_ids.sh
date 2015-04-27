#!/bin/sh

LOGFILE=/var/log/net_ids.log

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

reload_conf() {
  [ -f /etc/net_ids.conf ] && source /etc/net_ids.conf
  [ -n "$child_pid" ] && kill $child_pid
  [ -z "$ERROR_TIMEOUT" ] && ERROR_TIMEOUT=30
  [ -z "$PORT" ] && PORT=5000
  [ -z "$MAXLOGSIZE" ] && MAXLOGSIZE=0
  if [ -z "$LISTEN" -o "$LISTEN" != "1" ]; then
    LOCAL="-c $PORT"
  else 
    LOCAL="-p $PORT"
  fi
  do_reload=1
}

stop() {
  [ -n "$child_pid" ] && kill $child_pid
  exit 0
}

reload_conf

trap reload_conf SIGHUP
trap stop SIGTERM

while true; do 
  unset do_reload
  unset exit_code
  if [ "$ENABLED" = "1" -a -n "$SERVER" -a -n "$ID" ]; then
    [ "$MAXLOGSIZE" -gt "0" -a -f "$LOGFILE" ] && {
       [ "$MAXLOGSIZE" -le "`stat -c %s "$LOGFILE"`" ] && sed -i -e "1,3d" "$LOGFILE"
    }
    /usr/bin/net_ids $LOCAL -i $ID $SERVER 2>>"$LOGFILE" &
    child_pid=$!
    wait $child_pid
    exit_code=$?
    [ -n "$do_reload" -o "$exit_code" = "3" ] && continue
    sleep $ERROR_TIMEOUT &
    child_pid=$!
    wait $child_pid
    unset child_pid
  else
    sleep 3600 &
    child_pid=$!
    wait $child_pid
    unset child_pid
  fi
done
