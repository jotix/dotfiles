# OpenSUSE dotfiles

Install the following packages

  $ sudo zypper install git neofetch neovim helix stow lazygit

Install the dotfiles:

  $ ./stow-dotfiles.sh

Install QMK 

  $ sudo zypper install python311-pipx
  $ pipx install qmk

QMK dependencies

  $ sudo zypper install cross-avr-gcc7 cross-arm-none-gcc7 dfu-util dfu-programmer avrdude

Clone QMK repo

  $ git clone git@github.com:jotix/qmk_firmware.git
  $ cd qmk_firmware
  $ git remote add upstream https://github.com/qmk/qmk_firmware.git

QMK setup

  $ qmk setup
  
