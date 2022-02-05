#!/bin/bash
wgptbootpartsize=512 #512 MegaBytes
swapsize=1024 # 1024
pacstrap=$(pacstrap /mnt base linux linux-firmware vim openssh i3 xorg dmenu dhcpcd bash-completion sudo grub --noconfirm) #Base packes for install
tardisk="/dev/sdX" #edit this to target disk
hostname=""

echo "Partitioning Disk"
lsblk
parted $tardisk -s \
mklabel gpt \
mkpart ESP fat32 1MiB $gptbootpartsize+MiB \ #Uefi partition
set 1 boot on \
mkpart primary swap $gptbootpartsize+MiB $swapsize+MiB \ #Swap partition
set 2 swap on \
mkpart primary ext4 %100 \ #Root partition size
set 3 root on


echo "Mounting Partitions"
swapon $tardisk+2
mount $tardisk+3

echo "Mounting disks"
swapon $tardisk+2
mount $tardisk+3

echo "Installing linux "
$pacstrap

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Configuring Locales"
arch-chroot /mnt echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
arch-chroot /mnt echo "LANG=en_US.UTF-8" >> /etc/locale.conf
arch-chroot /mnt locale-gen

echo "Configuring Time"
arch-chroot /mnt timedatectl set-timezone US/Eastern
arch-chroot /mnt hwclock --systohc

echo "Configuring Hostname"
arch-chroot /mnt echo "$hostname" > /etc/hostname

echo "Configuring /etc/hosts"
arch-chroot /mnt



echo "Enabling Services"
arch-chroot /mnt systemctl enable dhcpcd.service
arch-chroot /mnt systemctl enable sshd.service
arch-chroot /mnt mkdir /boot/efi
arch-chroot /mnt mount $tardisk+1 /boot/efi

echo "Configuring Grub"
arch-chroot /mnt grub-install --target= --bootloader-id=grub_uefi
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


echo "Generating initfamfs"
arch-chroot /mnt mkinitcpio -P
arch-chroot /mnt
