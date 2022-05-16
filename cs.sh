#!/bin/bash

netmask()
{
    local mask=$((0xffffffff << (32 - $1))); shift
    local ip n
    for n in 1 2 3 4; do
        ip=$((mask & 0xff))${ip:+.}$ip
        mask=$((mask >> 8))
    done
    echo $ip
}

mount -a

d=$(cat /root/mds_disk)
cl=$(cat /root/cluster)
disk=`df -h |grep -v $d |grep $cl"-"|awk -F '/' '{print $NF}'`
#for i in $(ls -1 /vstorage|grep hdd);do
#echo $i
#done
#exit 0



#for i in $(ls -1 /vstorage|grep hdd);do
for i in $disk;do
# #vstorage -c $(cat /root/cluster) make-cs -r /vstorage/$i/cs -j /mnt/{{ cluster }}-{{ jrnl }}/$(echo $i|awk -F '-' '{print $2}')-jrnl -s {{ sizejrnl }};
  #vstorage -c $(cat /root/cluster) make-cs -r /vstorage/$i/cs 
  echo "vstorage -c $(cat /root/cluster) make-cs -r /vstorage/$i/cs >> /root/cs.sh"
  
done
echo "OR if ssd for journal: perl cs-ssd-jrnl.pl -c vstor001 "

#for i in $(ls -1 /vstorage|grep ssd));do
#  vstorage -c $(cat /root/cluster) make-cs -r /vstorage/$i/cs 
#done
systemctl restart vstorage-csd.target
echo "vstorage://$cl /vstorage/$cl fuse.vstorage rw,nosuid,nodev 0 0">> /etc/fstab
mount -a
mkdir -p  /vstorage/$(cat /root/cluster)/private/
mkdir -p  /vstorage/$(cat /root/cluster)/vmprivate/
ln -s /vstorage/$(cat /root/cluster)/private/ /vz/private
ln -s /vstorage/$(cat /root/cluster)/vmprivate/ /vz/vmprivate
mds_state=$(cat /root/mds)
if [[ $mds_state == "0" ]];then
    echo "Storage license is ACTIVATE."
    vstorage -c $cl load-license -f /root/lic-pc.txt
fi
echo "RVZ license is ACTIVATE"
vzlicload -f /root/lic-rvz.txt

systemctl restart cpufeatures.timer


IFS=". /" read -r i1 i2 i3 i4 mask <<< "$(cat /root/ip4)/$(cat /root/ip5)"
hastart -c $(cat /root/cluster) -n $(echo $i1.$i2.$i3).0/$(netmask $mask)
echo "hastart -c $(cat /root/cluster) -n $(echo $i1.$i2.$i3).0/$(netmask $mask)"