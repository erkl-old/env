#!/usr/bin/env sh
set -ex

# Install openssh.
sudo pacman -S --noconfirm openssh

# Initialize the authorized_keys and sshd_config files.
ln -sf "$HOME/.ssh/id_rsa.pub" "$HOME/.ssh/authorized_keys"
sudo ln -sf "$HOME/.env/ssh/sshd_config" "/etc/ssh/sshd_config"
