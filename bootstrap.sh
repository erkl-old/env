#!/usr/bin/env sh

# Stop at the first sign of trouble.
set -ex

# Install dependencies.
sudo pacman -S --noconfirm wget git openssh

# Download and decrypt the public and private keys.
mkdir -p ~/.ssh
wget -qO - https://github.com/erkl/env/raw/master/ssh/keys/id_rsa.encrypted | openssl enc -aes-256-cbc -d > ~/.ssh/id_rsa
wget -qO - https://github.com/erkl/env/raw/master/ssh/keys/id_rsa.pub.encrypted | openssl enc -aes-256-cbc -d > ~/.ssh/id_rsa.pub

# Set file permissions.
chmod 0700 ~/.ssh
chmod 0600 ~/.ssh/id_rsa
chmod 0644 ~/.ssh/id_rsa.pub

# Clone the whole repository.
git clone git@github.com:erkl/env.git ~/.env
