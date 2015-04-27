#!/bin/sh
avconv -i logo_stillag_clut224.bmp -vcodec rawvideo -f rawvideo -pix_fmt rgb565 -y tmp.txt
gzip -9 -c tmp.txt > tmp1.txt
exit
./bin2h tmp1.txt logo.c
#rm tmp1.txt tmp.txt
