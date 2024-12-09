#!/usr/bin/env bash


### install google-chrome from AUR
cd $HOME/Downloads
git clone https://aur.archlinux.org/google-chrome.git
cd google-chrome
makepkg -s
sudo pacman -U *.zst
cd
