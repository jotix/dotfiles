#!/usr/bin/env bash

set -e

echo
lsblk -o +LABEL
echo 
read -p "In which disk will NixOS be instaled: " DISK
DISK="/dev/$DISK"
if [[ ! -b $DISK ]]; then
    echo "The disk $DISK doesn't exist."
    exit
fi

echo 
read -p "Wich host install (jtx or ffm): " HOST
if [[ $HOST != "jtx" ]] && [[ $HOST != "ffm" ]]; then
    echo "The host $HOST doesn't exists"
    exit
fi
HOST=$HOST-arch

echo 
read -p "The disk $DISK will be complete deleted. Continue? (yes/no): " CONTINUE
if [[ $CONTINUE != "yes" ]]; then
    echo "Aborting installation."
    exit
fi

echo 
read -p "REALLY? (YES/NO): " CONTINUE
if [[ $CONTINUE != "YES" ]]; then
    echo "Aborting installation."
    exit
fi

echo
echo "Installing Arch Linux in $DISK"
echo "Hostname: $HOST"
echo

if [[ $HOSTNAME == "ffm-arch" ]] || [[ $HOSTNAME == "jtx-arch" ]]; then
    echo "Executing in testing mode..."
    exit
fi

### disk configuration ########################################################

# create partition table
sudo parted $DISK mklabel gpt

# make EFI & btrfs partitions
sudo parted --align optimal -- $DISK mkpart ARCH-BOOT fat32 1M 1G
sudo parted --align optimal -- $DISK mkpart Arch btrfs 1G 100%

# set esp flag in EFI partition
sudo parted $DISK set 1 esp on

# make the filesystems
sudo mkfs.vfat -F32 -n ARCH-BOOT /dev/disk/by-partlabel/ARCH-BOOT
sudo mkfs.btrfs -L Arch /dev/disk/by-partlabel/Arch -f

# Subvolumes Layout
# @          /
# @home      /home
# @snapshots /.snapshots
# @log       /var/log
# @cache     /var/cache
# @tmp       /var/tmp

# mount the disk & create the subvolumes
mount LABEL=Arch /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@tmp
umount -R /mnt

# make the directories
mount LABEL=Arch /mnt -osubvol=/@
mkdir -p /mnt/boot
mkdir -p /mnt/home
mkdir -p /mnt/.snapshots
mkdir -p /mnt/var/log
mkdir -p /mnt/var/cache
mkdir -p /mnt/var/tmp
mkdir -p /mnt/mnt/root-partition

# mount ESP part
mount LABEL=ARCH-BOOT /mnt/boot

# mounting btrfs main disk subvolumes
mount LABEL=Arch /mnt/home -osubvol=@home
mount LABEL=Arch /mnt/.snapshots -osubvol=@snapshots
mount LABEL=Arch /mnt/var/log -osubvol=@log
mount LABEL=Arch /mnt/var/cache -osubvol=@cache
mount LABEL=Arch /mnt/var/tmp -osubvol=@tmp
mount LABEL=Arch /mnt/mnt/root-partition -osubvol=/

if [[ -b "/dev/disk/by-label/jtx-ssd" ]]; then
  mkdir -p /mnt/mnt/jtx-ssd
  mount LABEL=jtx-ssd /mnt/mnt/jtx-ssd -osubvol=/
fi

if [[ -b "/dev/disk/by-label/jtx-nvme" ]]; then
  mkdir -p /mnt/mnt/jtx-nvme 
  mount LABEL=jtx-nvme /mnt/mnt/jtx-nvme -osubvol=/
fi

### enable parallel downloads
sed -i -e 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf

### install base system
pacstrap /mnt base linux linux-firmware

### generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

### enable parallel downloads in new installation
sed -i -e 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /mnt/etc/pacman.conf

### locale config
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime
arch-chroot /mnt hwclock --systohc
sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
sed -i -e 's/#es_AR.UTF-8/es_AR.UTF-8/g' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf

### install packages ##########################################################
PACKAGES="
networkmanager ntp
exfatprogs ntfs-3g dosfstools btrfs-progs
efibootmgr amd-ucode
unzip p7zip
base-devel cmake sudo
less man-pages man-db
exa bat fastfetch
ttf-jetbrains-mono ttf-jetbrains-mono-nerd 
ttf-ubuntu-font-family ttf-ubuntu-mono-nerd ttf-ubuntu-nerd
git lazygit openssh go
neovim emacs firefox
mesa xf86-video-amdgpu vulkan-radeon
plasma kde-applications tesseract-data-eng kitty rclone
cups ghostscript system-config-printer
"
arch-chroot /mnt pacman -S --noconfirm --needed $PACKAGES

### network configuration
echo jtx-arch > /mnt/etc/hostname

### config the bootloader
arch-chroot /mnt bootctl install
echo -e "default  arch.conf
timeout  5
console-mode max
editor   no
" > /mnt/boot/loader/loader.conf

echo -e "title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=LABEL=Arch rootflags=subvol=/@ rootfstype=btrfs rw
" > /mnt/boot/loader/entries/arch.conf

echo -e "title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux-fallback.img
options root=LABEL=Arch rootflags=subvol=/@ rootfstype=btrfs rw
" > /mnt/boot/loader/entries/arch-fallback.conf

### enable services
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable sddm
arch-chroot /mnt systemctl enable cups.service
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable ntpdate
arch-chroot systemctl enable libvirtd.service

### config sudo
sed -i -e 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudoers

### set the password & users
echo -e "\nSET ROOT PASSWORD\n"
arch-chroot /mnt passwd
echo -e "\nSET JOTIX PASSWORD\n"
arch-chroot /mnt useradd -m -G wheel -s /bin/bash jotix
arch-chroot /mnt passwd jotix
if [[ $HOST == "ffm-arch" ]]; then
    arch-chroot /mnt useradd -m -s /bin/bash filofem
    echo -e "\nSET FILOFEM PASSWORD\n"
    arch-chroot /mnt passwd filofem
fi

### install & config libvirt
arch-chroot /mnt pacman -S --noconfirm --ask=4 libvirt iptables-nft dnsmasq dmidecode virt-manager qemu-full
arch-chroot /mnt usermod -a -G libvirt jotix

### unmount & reboot
echo "Installation finished, you can do some final asjustements now or reboot and use the new system:
> umount -R /mnt
> reboot"
