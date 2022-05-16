#!/bin/bash
echo "Run on first node!!!"

count=
name="node0"
ssh-keygen -b 2048 -t rsa -f /root/.ssh/migrate -N ""

for (( i=1; i<= $count; i++ )); do
 echo $name$i
 key=`cat /root/.ssh/migrate.pub|awk -F ' ' '{print $2}'`
 echo "ssh-rsa " $key" root@"$name$i   >>/root/.ssh/authorized_keys
done
for (( i=1; i<= $count; i++ )); do
 echo $name$i
 `scp /root/.ssh/migrat* /root/.ssh/authorized_keys root@$name$i:/root `
done
