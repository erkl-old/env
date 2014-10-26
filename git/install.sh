#!/usr/bin/env sh

# Stop at the first sign of trouble.
set -ex

# Install git.
sudo pacman -S --noconfirm git

# Activate .gitconfig.
ln -sf "$HOME/.env/git/.gitconfig" "$HOME/.gitconfig"
