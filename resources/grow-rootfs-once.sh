#!/bin/sh

# This script is not very smart.
[ "$1" == "yes I really mean it" ] || exit

p=2
rp=`df / | awk '$6 == "/" {print $1}'`
rd=`echo $rp | sed 's/p[[:digit:]]\+//g'`

echo Growing partition and filesystem to fill sdcard...
cat <<EOF | fdisk "$rd"
e
$p

w
EOF

resize2fs $rp

systemctl disable grow-rootfs-once.service
