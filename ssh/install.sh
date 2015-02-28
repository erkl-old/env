#!/usr/bin/env sh
set -ex

# Install openssh.
sudo pacman -S --noconfirm openssh

# Decrypt our SSH keys, if we haven't already.
if [ ! -e "$HOME/.ssh/id_rsa" -o ! -e "$HOME/.ssh/id_rsa.pub" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 0700 "$HOME/.ssh"

    openssl enc -aes-256-cbc -d -base64 -in "$HOME/.env/ssh/keys/id_rsa.enc" -out "$HOME/.ssh/id_rsa"
    openssl enc -aes-256-cbc -d -base64 -in "$HOME/.env/ssh/keys/id_rsa.pub.enc" -out "$HOME/.ssh/id_rsa.pub"

    chmod 0600 "$HOME/.ssh/id_rsa"
    chmod 0644 "$HOME/.ssh/id_rsa.pub"
fi

# Initialize the authorized_keys and sshd_config files.
ln -sf "$HOME/.ssh/id_rsa.pub" "$HOME/.ssh/authorized_keys"
sudo ln -sf "$HOME/.env/ssh/sshd_config" "/etc/ssh/sshd_config"
