#!/bin/bash
# centos7
yum -y install policycoreutils-python
port=$(rand 10000 60000)
sed -i 's/.*Port .*/Port '$port'/g' /etc/ssh/sshd_config
semanage port -a -t ssh_port_t -p tcp $port
firewall-cmd --permanent --add-port=$port/tcp
firewall-cmd --reload
systemctl restart sshd.service
clear
echo .
echo ===
echo ssh端口$port
echo ===

#生成随机端口
rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))  
}