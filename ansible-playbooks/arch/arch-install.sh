#!/bin/sh

if [[ $(git config --list | grep user | wc -c) -eq 0 ]]; then
  echo "setting git config globals"
  git config --global user.name "Jared McQueen"
  git config --global user.email "jaredmcqueen@gmail.com"
fi
echo "git config set"


if ! [ -x "$(command -v ansible-galaxy)" ]; then
  echo "installing ansible"
  sudo pacman -S ansible
fi
echo "ansible is installed"

# check for kewlfft.aur
if [[ $(ansible-galaxy collection list |grep kewlfft.aur | wc -c) -eq 0 ]]; then
  echo "ansible galaxy kewlfft.aur plugin not installed"
  ansible-galaxy collection install kewlfft.aur
  ansible-galaxy collection install community.kubernetes
fi
echo "ansible plugin kewlfft.aur installed"

# check for community.kubernetes
if [[ $(ansible-galaxy collection list |grep community.kubernetes | wc -c) -eq 0 ]]; then
  echo "ansible galaxy community.kubernetes plugin not installed"
  ansible-galaxy collection install community.kubernetes
fi
echo "ansible plugin community.kubernetes installed"

# check for yay
if ! [ -x "$(command -v yay)" ]; then
  echo "yay not installed"
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg -si --noconfirm
  rm -rf yay-bin
  cd ..
fi
echo "yay is installed"

# run ansible
echo "running playbook"
ansible-playbook $(pwd)/playbook.yaml --ask-vault-pass --ask-become-pass -v | tee logs.txt
