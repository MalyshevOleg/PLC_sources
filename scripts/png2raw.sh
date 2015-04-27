#!/bin/sh
[ -z "$1" ] && exit
echo "static unsigned char spk_logo[] = {";
ffmpeg -vcodec png -i $1 -vcodec rawvideo -f rawvideo -pix_fmt rgb565 - | gzip -9 -c | bin2h 32
echo "};";
