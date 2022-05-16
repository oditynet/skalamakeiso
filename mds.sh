#!/bin/bash

mds_ipmaster=$(cat /root/mds_ipmaster)
ip4=$(cat /root/ip4)
mds_state=$(cat /root/mds)
cluster=$(cat /root/cluster)
mds_disk=$(cat /root/mds_disk)

result=`df -h |grep $mds_disk | awk '{ print $NF }'`
echo $result
if [[ $cluster && $mds_state && $mds_ipmaster && $ip4 && $mds_disk  ]];then
    if [ $mds_state -eq 0 ];then
	echo "Create master MDS."
	echo 'P@$$w0rd'|vstorage -c $cluster make-mds -I -a $mds_ipmaster -r $result/mds -P
    fi
    if [ $mds_state -eq 1 ];then
	echo "Create slave MDS."
	echo 'P@$$w0rd'|vstorage -c $cluster auth-node -b $mds_ipmaster -P; vstorage -c $cluster make-mds -a $ip4 -r  $result/mds
    fi
    if [ $mds_state -eq 2 ];then
	echo "Register MDS only."
	echo 'P@$$w0rd'|vstorage -c $cluster auth-node -b $mds_ipmaster -P
    fi
systemctl restart vstorage-mdsd.target

fi