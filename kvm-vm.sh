#!/bin/bash
# 参考原文https://www.server-world.info/en/note?os=CentOS_Stream_8&p=kvm&f=1
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

# 创建虚拟机镜像文件夹
mkdir -p /var/kvm/images

# 创建虚拟机
virt-install \
--name centos-st8 \
--ram 4096 \
--disk path=/var/kvm/images/centos-st8.img,size=30 \
--vcpus 2 \
--os-variant centos-stream8 \
--network bridge=br0 \
--graphics none \
--console pty,target_type=serial \
--location /home/CentOS-Stream-8-x86_64-latest-dvd1.iso \
--extra-args 'console=ttyS0,115200n8'

# --name 指定虚拟机名称
# --ram	 指定内存容量单位MB
# --disk path=xxx,size=xxx	[path=xxx] : 指定虚拟磁盘位置 (默认在 [/var/lib/libvirt/images])
# [size=xxx] : 指定磁盘大小
# --vcpus	 指定虚拟机CPU核数
# --os-variant  指定虚拟机操作系统类型
# 具体类型可以使用命令获取 osinfo-query os
# --network	 指定虚拟机网络类型
# --graphics	 指定虚拟机图形类型，可选spice, vnc, none and so on
# --console  指定控制台类型
# --location  指定安装源
# --extra-args  其他额外参数

# 连接到虚拟机控制台
virsh console centos-st8

# 克隆虚拟机
virt-clone --original centos-st8 --name template --file /var/kvm/images/template.img
# 克隆后的磁盘文件
ll /var/kvm/images/template.img
# 克隆后的虚拟机配置文件
ll /etc/libvirt/qemu/template.xml

# 虚拟机操作

# 虚拟机开机
virsh start centos-st8
# 虚拟机开机并连接控制台
virsh start centos-st8 --console
# 设置虚拟机自动开机
virsh autostart centos-st8
# 取消虚拟机自动开机
virsh autostart --disable centos-st8
# 运行的虚拟机列表
virsh list
# 所有虚拟机,含未开机的
virsh list --all

# 虚拟机管理工具

# 安装包
dnf -y install libguestfs-tools virt-top
# 显示可用的操作系统模板
virt-builder -l
# 创建一台虚拟机镜像,密码替换为你的密码
virt-builder centos-8.2 --format qcow2 --size 10G -o /var/kvm/images/centos-8.2.qcow2 --root-password password:myrootpassword
# 以上面的镜像创建一台虚拟机
virt-install \
--name centos-8.2 \
--ram 4096 \
--disk path=/var/kvm/images/centos-8.2.qcow2 \
--vcpus 2 \
--os-variant centos8 \
--network bridge=br0 \
--graphics none \
--serial pty \
--console pty \
--boot hd \
--import
# 查看虚拟机中的某个目录
virt-ls -l -d centos-st8 /root
# 查看虚拟机中的某个文件
virt-cat -d centos-st8 /etc/passwd
# 编辑虚拟机中的某个文件
virt-edit -d centos-st8 /etc/fstab
# 显示虚拟机磁盘使用情况
 virt-df -d centos-st8
# 挂载虚拟机磁盘
guestmount -d centos-st8 -i /media
# 显示虚拟机的状态
virt-top

# 图形化链接支持

# 安装spice服务端
dnf -y install spice-server
# 编辑虚拟机配置
virsh edit centos-st8
# 添加以下内容
# 设置链接密码 [passwd=***] 
# 指定唯一槽位号 [slot='0x**']
#     <graphics type='spice' port='5900' autoport='no' listen='0.0.0.0' passwd='password'>
#       <listen type='address' address='0.0.0.0'/>
#     </graphics>
#     <sound model='ich6'>
#       <address type='pci' domain='0x0000' bus='0x00' slot='0x09' function='0x0'/>
#     </sound>
#     <video>
#       <model type='qxl' ram='65536' vram='32768' heads='1'/>
#       <address type='pci' domain='0x0000' bus='0x00' slot='0x10' function='0x0'/>
#     </video>
#     <memballoon model='virtio'>在这行上面添加
# 开始虚拟机
virsh start centos-st8
# 放行防火墙
firewall-cmd --add-port=5900-5910/tcp --permanent
# 重启防火墙
firewall-cmd --reload

# 创建虚拟机时指定spice
virt-install \
--name Win2k19 \
--ram 6144 \
--disk path=/var/kvm/images/Win2k19.img,size=100 \
--vcpus 4 \
--os-variant win2k19 \
--network bridge=br0 \
--graphics spice,listen=0.0.0.0,password=password,keymap=ja \
--video qxl \
--cdrom /tmp/Win2019_JA-JP.ISO

# 安装SPICE客户端,在GUI的linux下面
dnf install virt-viewer
# 输入链接,spice://(server name or IP address):(port)] and click the [Connect] button.
# windows版本下载地址https://virt-manager.org/

# UEFI引导的虚拟机
# 安装UEFI软件
dnf -y install edk2-ovmf
# 创建UEFI启动的虚拟机
virt-install \
--name Win2k19 \
--ram 6144 \
--disk path=/var/kvm/images/Win2k19.img,size=100 \
--vcpus 4 \
--os-variant win2k19 \
--network bridge=br0 \
--graphics vnc,listen=0.0.0.0,password=password \
--video qxl \
--cdrom /home/Win2019_EN-US.iso \
--boot uefi

# 设置GPU硬直通
# 编辑GRUB文件
vi /etc/default/grub
# 第六行添加 intel_iommu=on (如果是AMD CPU则添加 [amd_iommu=on])
# GRUB_TIMEOUT=5
# GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
# GRUB_DEFAULT=saved
# GRUB_DISABLE_SUBMENU=true
# GRUB_TERMINAL_OUTPUT="console"
# GRUB_CMDLINE_LINUX="crashkernel=auto resume=/dev/mapper/cl-swap rd.lvm.lv=cl/root rd.lvm.lv=cl/swap rhgb quiet intel_iommu=on"
# GRUB_DISABLE_RECOVERY="true"
# GRUB_ENABLE_BLSCFG=true
# 重新生成引导文件
grub2-mkconfig -o /boot/grub2/grub.cfg
# 查看显卡VID/DID
# PCI number ⇒ it matchs [02:00.*] below
# vendor-ID:device-ID ⇒ it matchs [10de:***] below
lspci -nn | grep -i nvidia
# 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP104 [GeForce GTX 1070] [10de:1b81] (rev a1)
# 01:00.1 Audio device [0403]: NVIDIA Corporation GP104 High Definition Audio Controller [10de:10f0] (rev a1)
# 编辑内核文件
vi /etc/modprobe.d/vfio.conf
# 添加内容 options vfio-pci ids=10de:1b81,10de:10f0
# 添加内核模块加载
echo 'vfio-pci' > /etc/modules-load.d/vfio-pci.conf
# 重启宿主机
reboot
# 确认IOMMU是否生效
dmesg | grep -E "DMAR|IOMMU"
# [    0.000000] ACPI: DMAR 0x00000000DC44CC70 0000BC (v01 A M I  OEMDMAR  00000001 INTL 00000001)
# [    0.000000] DMAR: IOMMU enabled
# [    0.000000] DMAR: Host address width 46
# [    0.000000] DMAR: DRHD base: 0x000000fbffc000 flags: 0x1
# [    0.000000] DMAR: dmar0: reg_base_addr fbffc000 ver 1:0 cap d2078c106f0466 ecap f020de
# [    0.000000] DMAR: RMRR base: 0x000000dc315000 end: 0x000000dc321fff
# [    0.000000] DMAR: ATSR flags: 0x0
# [    0.000000] DMAR: RHSA base: 0x000000fbffc000 proximity domain: 0x0
# [    0.000000] DMAR-IR: IOAPIC id 0 under DRHD base  0xfbffc000 IOMMU 0
# [    0.000000] DMAR-IR: IOAPIC id 2 under DRHD base  0xfbffc000 IOMMU 0
# [    0.000000] DMAR-IR: HPET id 0 under DRHD base 0xfbffc000
# [    0.000000] DMAR-IR: Queued invalidation will be enabled to support x2apic and Intr-remapping.
# [    0.000000] DMAR-IR: Enabled IRQ remapping in x2apic mode
# [    1.238032] DMAR: dmar0: Using Queued invalidation
# 确认vfio是否生效
dmesg | grep -i vfio
# [    4.783160] VFIO - User Level meta-driver version: 0.3
# [    4.794903] vfio_pci: add [10de:1b81[ffff:ffff]] class 0x000000/00000000
# [    4.807042] vfio_pci: add [10de:10f0[ffff:ffff]] class 0x000000/00000000
# 创建硬直通的虚拟机
virt-install \
--name centos-st8 \
--ram 8192 \
--disk path=/var/kvm/images/centos-st8.img,size=30 \
--vcpus 4 \
--os-variant centos-stream8 \
--network bridge=br0 \
--graphics none \
--console pty,target_type=serial \
--location /home/CentOS-Stream-8-x86_64-20201203-dvd1.iso \
--extra-args 'console=ttyS0,115200n8 serial' \
--host-device 01:00.0 \
--features kvm_hidden=on \
--machine q35
# 虚拟机安装后,查看是否有GPU
lspci | grep -i nvidia

# 使用TPM2.0虚拟机,安装windows11使用
dnf --enablerepo=epel -y install edk2-ovmf swtpm swtpm-tools
# 创建windows11虚拟机
virt-install \
--name Windows_11 \
--ram 6144 \
--disk path=/var/kvm/images/Windows_11.img,size=80 \
--cpu host-passthrough \
--vcpus=4 \
--os-variant=win10 \
--network bridge=br0 \
--graphics vnc,listen=0.0.0.0,password=password \
--video virtio \
--cdrom /home/Win11_English_x64.iso \
--features kvm_hidden=on,smm=on \
--tpm backend.type=emulator,backend.version=2.0,model=tpm-tis \
--boot loader=/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd,loader_ro=yes,loader_type=pflash,nvram_template=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd 

# 连接图形界面
virt-viewer --connect qemu:///system --wait Windows_11

# 增加串口
virsh edit vmname
<serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>

# 虚拟机重置密码
dnf install libguestfs-tools
virsh shutdown vm
virsh dumpxml vm |grep 'source file'
# 查看虚拟机磁盘文件
# 生成秘文
​openssl passwd -1 密码
# 复制生成的密文
​guestfish --rw -a /xx/xx/xx.img
​><fs>中依次输入
​launch
​list-filesystems
​mount /dev/vda /
​vi /etc/shadow
粘贴密文
​quit
​virsh start vm
