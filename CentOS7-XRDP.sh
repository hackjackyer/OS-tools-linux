#!/bin/bash
echo install GUI
yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
clean
echo boot GUI
ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target

echo install xrdp
wget http://mirrors.sohu.com/fedora-epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
yum clean all
yum install xrdp -y
systemctl enable xrdp.service
systemctl start xrdp.service

echo setting firewall
firewall-cmd --permanent --zone=public --add-port=3389/tcp
firewall-cmd --reload
