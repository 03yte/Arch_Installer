#!/bin/bash
gptbootpartsize=512 
swapsize=1024 
pacstrap="base linux linux-firmware vim openssh i3 xorg dmenu dhcpcd bash-completion sudo grub --noconfirm" #Base packages for install
tardisk="/dev/vda" #edit this to target disk
hostname="thename"

umount ${tardisk}1
umount ${tardisk}3
swapoff ${tardisk}2

echo "Partitioning Disk"
parted -s ${tardisk} -a optimal mklabel gpt
parted -s ${tardisk} -a optimal mkpart ESP fat32 1MiB ${gptbootpartsize}MiB
parted -s ${tardisk} set 1 boot on
parted -s ${tardisk} -a optimal mkpart primary linux-swap ${gptbootpartsize}MiB $[gptbootpartsize+swapsize]MiB
parted -s ${tardisk} set 2 swap on
parted -s ${tardisk} -a optimal mkpart primary ext4 $[gptbootpartsize+swapsize]MiB 100% 

echo "Formatting Partitions"
yes | mkfs.fat -F32 ${tardisk}1
yes | mkswap ${tardisk}2
yes | mkfs.ext4 ${tardisk}3

echo "Mounting Partitions"
swapon ${tardisk}2
mount ${tardisk}3 /mnt

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Installing linux"
pacstrap /mnt base linux linux-firmware vim sudo grub efibootmgr os-prober dhcpcd rsync openssh dhcpcd --noconfirm

arch-chroot /mnt /bin/bash << EOF
echo "Configuring Locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen
echo "Configuring Time"
timedatectl set-timezone US/Eastern
hwclock --systohc
echo "Configuring Hostname"
echo $hostname > /etc/hostname
echo "Configuring /etc/hosts"
echo "127.0.0.1		localhost"
echo "::1		localhost"
echo "127.0.1.1		${hostname}.localdomain	${hostname}"
echo "Enabling Services"
systemctl enable dhcpcd.service
systemctl enable sshd.service
mkdir /boot/efi
mount ${tardisk}1 /boot/efi
echo "Configuring Grub"
grub-install --target=x86_64-efi --bootloader-id=grub_uefi
grub-mkconfig -o /boot/grub/grub.cfg
echo "Generating initfamfs"
mkinitcpio -P
EOF
