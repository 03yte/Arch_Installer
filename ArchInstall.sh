#!/bin/bash

#https://linuxhint.com/linux-parted-command-line-examples/

#Variables
totalmem=$(awk '/MemTotal/ { printf("%d\n",$2 * 1024 )}' /proc/meminfo) #Currrent memory installed in Bytes, from KB
gptbootpartsize=524288 #512 MegaBytes
swapsize=$totalmem+$gptbootpartsize #Default swap size is the total amount of memory in system during installation, this can be changed with the -r flag 
pacstrap=$(pacstrap /mnt base linux linux-firmware vim openssh i3 xorg dmenu dhcpcd bash-completion sudo grub) #Base packes for install



echo "Bash case handling"
while getopts 'brdt' OPTION; do
    case "$OPTION" in 
    b)
        #Bootmode
        if [$OPTARG == "uefi" || $OPTARG == "bios"]
        then
            boottype=$OPTARG
            echo "Boot mode selected: $OPTARG"
            #### continue
        else
            echo "Invalid bootmode selected"
            exit 0
            #error out with reason 
        fi  
        ;;
    r)  
        if [$OPTARG >= "0"]
            totalmem=$OPTARG
            echo "Custom memory option detected"
            echo "Ram total: $totalmem"
        else
            echo "No memory option detected, using defaults."
            echo "Ram total: $totalmem"
        fi
        ;;
    d)
        if [$OPTARG ]
        ;;
    
    n)

        ;;

    h)
        #help
        echo "Usage: [-b value] [-r value] [-d value] [-t value]"
        echo "-b value | Bootmode  | [u -uefi] [b -bios]"
        echo "-r value | Ram Total | value in Bytes]"
        echo "-d value | Disk Path | value ex. /dev/vda"
        echo ::
        ;;
    esac
done

#bootmodedetect (){
#    #If efivars exists, or other methods for detections
#}

diskform (){
    lsblk
    parted $tardisk -s \
    mklabel gpt \
    if [$boottype == "b"]{
    then
        mkpart ESP fat32 1MiB $gptbootpartsize \ #Uefi partition
        set 1 boot on \
    elif [$boottype == "u"]
    then
        mkpart bios_grub fat32 1MiB $gptbootpartsize \ #Bios partition
        set 1 boot on \
    fi

    mkpart primary swap $gptboot $swapsize \ # Swap partition
    set 2 swap on \

    mkpart primary ext4 100% \ # Root partition
    set 3 root on

    echo "Mounting Partitions"
    swapon $tardisk+2
    mount $tardisk+3

    echo "Generating fstab file"
    genfstab -U /mnt >> /mnt/etc/fstab
} 

chroot (){
    echo "Chrooting to install disk"
    arch-chroot /mnt

    echo "Configuring Locales"
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    locale-gen

    echo "Enabling Services"
    systemctl enable dhcpcd.service
    systemctl enable sshd.service

    echo "Configuring Grub"
    if [$boottype == "b"]{
    then
        grub-install --target=i386-pc $tardisk
        grub-mkconfig -o /boot/grub/grub.cfg

    elif [$boottype == "u"]
    then
        mkdir /boot/efi
        mount $tardisk+1 /boot/efi
        grub-install --target= --bootloader-id=grub_uefi
        grub-mkconfig -o /boot/grub/grub.cfg
    fi

}

mkinitcpio -P
timedatectl set-timezone US/Eastern

