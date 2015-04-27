#!/bin/bash
src_platf="spk207.03.web"
chk_platf="spk207.03 spk207.03.web spk207.04 spk207.04.web spk210.03 spk210.03.web spk210.04 spk210.04.web "
files="config.mk"
for i in $chk_platf; do
  tmpdiff=`mktemp tmpXXXXXX`
  for j in $files; do
    diff -uNr ../config/platforms/$src_platf/$j ../config/platforms/$i/$j >>$tmpdiff
  done
  sz=`stat -c %s $tmpdiff`
  if [ $sz -ne 0 ]; then
    echo "############################### $src_platf to $i ###############################"
    cat $tmpdiff
  fi
  rm $tmpdiff
done