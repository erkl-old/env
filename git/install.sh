#!/usr/bin/env sh
set -ex

# Install git.
sudo pacman -S --noconfirm git

# Activate .gitconfig.
ln -sf "$HOME/.env/git/.gitconfig" "$HOME/.gitconfig"
