#!/bin/bash
# 以centos8为例
# 安装虚拟化软件
dnf -y install qemu-kvm libvirt virt-install

# 确认内核模块已加载
lsmod | grep kvm

# kvm_intel             311296  0
# kvm                   839680  1 kvm_intel
# irqbypass              16384  1 kvm

# 设置开机自启动
systemctl enable --now libvirtd

# 添加网桥
nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
# 设置网桥网络参数
nmcli connection modify br0 ipv4.addresses 10.0.0.30/24 ipv4.method manual
nmcli connection modify br0 ipv4.gateway 10.0.0.1
nmcli connection modify br0 ipv4.dns 10.0.0.10

# 删除网卡，作为网桥子卡，这里以你的电脑网卡是enp1s0为例
nmcli connection del enp1s0
nmcli connection add type bridge-slave autoconnect yes con-name enp1s0 ifname enp1s0 master br0

# 重启，电脑，确认网桥配置成功。
reboot
ip addr
