#!/bin/sh
# $1 - basedir, $2 - platform
# output - machine
for i in $1/config/platforms/*.map; do
  [ -f $i ] && cat $i | grep $2 >/dev/null && { echo $i | sed -r 's,^.*/([^/]*)\.map$,\1,'; exit 0; }
done
