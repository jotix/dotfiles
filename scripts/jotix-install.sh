#!/usr/bin/env bash

### install jotix
/mnt/jtx-ssd/jotix/jotix-install.sh

### use ssh repos in arch-config
git remote remove origin
git remote add origin git@github.com:jotix/arch-config.git

### libvirt install & config
sudo pacman -S libvirt iptables-nft dnsmasq dmidecode virt-manager qemu-full
sudo usermod -a -G libvirt jotix
sudo systemctl enable libvirtd.service --now

### powerline-go
go install github.com/justjanne/powerline-go@latest

### printer drivers
sudo pacman -U --noconfirm $HOME/arch-config/printer-drivers/*.zst

### syncthing
# sudo pacman -S --noconfirm --needed syncthing
# sudo systemctl enable syncthing.service --user --now

### install google-chrome from AUR
cd $HOME/Downloads
git clone https://aur.archlinux.org/google-chrome.git
cd google-chrome
makepkg -s
sudo pacman -U *.zst
cd
