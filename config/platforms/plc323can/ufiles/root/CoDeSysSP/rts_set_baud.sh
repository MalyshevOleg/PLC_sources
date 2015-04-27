echo $1 $2
ip link set $1 down
baud=$2"000"
echo $baud
ip link set $1 type can bitrate $baud
ip link set $1 up
