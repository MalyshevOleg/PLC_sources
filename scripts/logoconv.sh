EXPECTED_ARGS=1
E_BADARGS=65
if [ $# -ne $EXPECTED_ARGS ]
then
    echo "Usage: `logoconv $0` {arg}"
    echo "use with param ( name of png file)"
    echo "need preinstalled netpbm package"
    exit $E_BADARGS
    fi
NAME=`echo "$1" |cut -d'.' -f1`
ext_ppm=".ppm"
echo $NAME$ext_ppm
convert $1 temporal1.ppm
ppmquant 224 temporal1.ppm > temporal2.ppm
pnmnoraw temporal2.ppm > $NAME$ext_ppm
rm temporal*
cp $NAME$ext_ppm ../build/src/linux-3.0/drivers/video/logo