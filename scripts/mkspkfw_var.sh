#!/bin/bash

dump_string() {
  printf "%08x" "${#2}" | xxd -g0 -r -p | perl -0777e 'print scalar reverse <>' >>$1
  echo -n $2 >>$1
}

dump_string_866() {
  dump_string $1 `echo "$2" | iconv -f utf-8 -t cp866`
}

dump_num() {
  printf "%08x" $2 | xxd -g0 -r -p | perl -0777e 'print scalar reverse <>' >>$1
}

dump_file() {
  sz=0
  [ -n "$2" ] && sz=`stat -c %s "$2"`
  dump_num $1 $sz
  [ -n "$2" ] && cat "$2" >>$1
}

dump_file_866() {
  local tmpfile
  tmpfile=`mktemp tmpXXXXXX`
  cat $2 | iconv -f utf-8 -t cp866 >$tmpfile
  dump_file $1 $tmpfile
  rm $tmpfile
}

dump_cmd_file()
{
  local tmpfile
  tmpfile=`mktemp tmpXXXXXX`
  cat $2 | iconv -f utf-8 -t cp866 | sed -r "s,(\".*\"|'.*')|(#.*\$),\1,g" | sed '/^$/d' >$tmpfile
  dump_file $1 $tmpfile
  rm $tmpfile
}

dump_hex() {
  echo $2 | xxd -g0 -r -p | perl -0777e 'print scalar reverse <>' >>$1
}

dst_file=$1; shift

[ -z "$dst_file" ] && { echo "error: no args specified"; exit 1; }

echo -n >$dst_file

files=""

while true; do
  block=$1; shift
  cmd=$1; shift
  filename=$1; shift
  [ -z "$block" ] && break
  [ -z "$cmd" ] && { echo "error: invalid block descriptor: no args" >&2; exit 1; }
  [ "$filename" == "-" ] && unset filename
  [ -z "$filename" ] && {
    [ "$block" == "BOARD" -o "$block" == "VERSION" ] || { echo "error: empty block is only BOARD or VERSION" >&2; exit 1; }
  }
  [ -z "$filename" -o -f "$filename" ] || { echo "error: file $filename not found" >&2; exit 1; }
  tmpfile=`mktemp tmpXXXXXX`
  dump_string_866 $tmpfile "$block"
  if [[ $cmd =~ ^-(.*) ]]; then
    dump_cmd_file "$tmpfile" "${BASH_REMATCH[1]}"
  else
    dump_string_866 "$tmpfile" "$cmd"
  fi
  dump_file "$tmpfile" "$filename"
  files="$files $tmpfile"
done

for f in $files; do
  cat $f >>$dst_file
  dump_hex $dst_file `crc32 $dst_file`
  rm $f
done
