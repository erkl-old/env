#!/usr/bin/env sh

# Stop at the first sign of trouble.
set -ex

# Install zsh and make it the current user's default shell.
sudo pacman -S --noconfirm zsh
chsh -s /bin/zsh

# Install .zshrc.
ln -s "$HOME/.env/zsh/.zshrc" "$HOME/.zshrc"
