#!/bin/bash

vlan=$(cat /root/vlan)

mkdir /root/oldnetwork
cp -r /etc/sysconfig/network-scripts/ifcfg-* /root/oldnetwork/
rm -rf /etc/sysconfig/network-scripts/ifcfg-*

ethernet=`nmcli con show | awk '{print $1}'|grep -v lo|grep -v virbr0`
for DEV in ${ethernet[@]} ; do
   nmcli con delete $DEV
done

nmcli con add type bond con-name bond0 ifname bond0 bond.options "mode=802.3ad,miimon=100,updelay=0,downdelay=0"
nmcli con modify bond0 ipv4.never-default yes
nmcli con modify bond0 ipv6.method ignore
nmcli con modify bond0 ipv4.addresses $(cat /root/ip4)/$(cat /root/ip5)
nmcli con modify bond0 ipv4.method manual

nmcli con add type bond-slave ifname $(cat /root/eth0) con-name $(cat /root/eth0) master bond0
nmcli con modify $(cat /root/eth0) 802-3-ethernet.mtu 9216

nmcli con add type bond-slave ifname $(cat /root/eth1) con-name $(cat /root/eth1) master bond0
nmcli con modify $(cat /root/eth1) 802-3-ethernet.mtu 9216

nmcli con modify bond0 802-3-ethernet.mtu 9216

if [[ $eth10 ]];then
nmcli con add type bond con-name bond1 ifname bond1 bond.options "mode=802.3ad,miimon=100,updelay=0,downdelay=0"
nmcli con modify bond1 ipv6.method ignore
nmcli con modify bond1 ipv4.method disable
nmcli con add type bond-slave ifname $(cat /root/eth10) con-name $(cat /root/eth10) master bond1
nmcli con modify $(cat /root/eth10) 802-3-ethernet.mtu 9216
nmcli con add type bond-slave ifname $(cat /root/eth11) con-name $(cat /root/eth11) master bond1
nmcli con modify $(cat /root/eth11) 802-3-ethernet.mtu 9216

nmcli con modify bond1 802-3-ethernet.mtu 9216
fi

nmcli con add type bridge con-name $(cat /root/eth2) ifname $(cat /root/eth2)
nmcli con modify $(cat /root/eth2) bridge.stp no
nmcli con modify $(cat /root/eth2) ipv6.method ignore
nmcli con modify $(cat /root/eth2) ipv4.addresses $(cat /root/ip1)/$(cat /root/ip2)
nmcli con modify $(cat /root/eth2) ipv4.gateway $(cat /root/ip3)
nmcli con modify $(cat /root/eth2) ipv4.method manual

if [[ $vlan ]];then
nmcli con add type vlan con-name $(cat /root/eth20).$(cat /root/vlan) ifname $(cat /root/eth20).$(cat /root/vlan) dev $(cat /root/eth20) id $(cat /root/vlan)
nmcli con add type bridge-slave con-name $(cat /root/eth20).$(cat /root/vlan) ifname $(cat /root/eth20).$(cat /root/vlan) master  $(cat /root/eth2)
nmcli con modify $(cat /root/eth20).$(cat /root/vlan) 802-3-ethernet.mtu 9216
nmcli con modify $(cat /root/eth20).$(cat /root/vlan) ipv6.method ignore
nmcli con modify $(cat /root/eth20).$(cat /root/vlan) ipv4.method disable

nmcli con modify $(cat /root/eth20) ipv4.method disable


else
nmcli con add type bridge-slave con-name $(cat /root/eth20) ifname $(cat /root/eth20) master  $(cat /root/eth2)
fi
#rm -rf /root/eth*
#rm -rf /root/ip*
#rm -rf /root/sd*
#rm -rf /root/vlan
#rm -rf /root/ssds
#rm -rf /root/hdds

#yum localinstall /root/update701335/*.rpm -y
#rm -rf /root/update701335
systemctl restart network
nmcli con show

rm -rf /etc/firewalld/zones/trusted.xml 
cp  /usr/lib/firewalld/zones/trusted.xml /etc/firewalld/zones/
for i in $(firewall-cmd --list-interfaces); do firewall-cmd --zone=trusted --change-interface=$i; done
firewall-cmd --reload



systemctl enable chronyd
systemctl restart chronyd

hostnamectl set-hostname $(cat /root/namehost)
sed -i '/^server/d'  /etc/chrony.conf
sed -i '1s/^/server '$(cat /root/ntp)' iburst\n/g' /etc/chrony.conf
str="$(cat /root/ip4)	$(cat /root/namehost).localdomain	$(cat /root/namehost)"
ssh $(cat /root/mds_ipmaster) "echo '$str' >> /etc/hosts"

find /etc/yum.repos.d/ -type f -exec sed -i "s/enabled=1/enabled=0/g" {} \;
echo -e "[local]\nname=Local Yum Repo\nbaseurl=file:///media/flash/\nenabled=1\ngpgcheck=0" >> /etc/yum.repos.d/local-repo.repo
mkdir /media/flash/
echo '/root/r-virt.iso /media/flash iso9660 noexec,nosuid,nodev,loop     0 0' >> /etc/fstab


echo "Edit file /root/ssh-keygen (count nodes) and run on first node!"
