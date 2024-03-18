#!/bin/bash
#
sudo apt install git gcc pipx neofetch

sudo snap install go --classic
sudo snap install nvim --classic
sudo snap install helix --classic

### powerline-go
go install github.com/justjanne/powerline-go@latest

### lazygit
go install github.com/jesseduffield/lazygit@latest

### qmk
pipx install qmk
