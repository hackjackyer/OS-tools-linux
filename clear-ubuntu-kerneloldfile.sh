#!/bin/bash
# 重启服务器，应用最新版内核镜像
# dpkg --list 'linux-image*' | grep ^ii |grep linux-image-4.4.0 |awk '{printf $2}'>list.txt
# 删除list.txt文件里最新版镜像名字那行。
for i in `cat list.txt`
do
    apt-get remove $i -y
done
apt-get autoremove -y
# 运行后/boot分区应该会有很多空闲空间了