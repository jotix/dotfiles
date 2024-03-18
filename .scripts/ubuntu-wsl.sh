#!/bin/bash
#
sudo apt install git gcc

sudo snap install go nvim --classic pipx

### powerline-go
go install github.com/justjanne/powerline-go@latest

### lazygit
go install github.com/jesseduffield/lazygit@latest

### qmk
pipx install qmk
