#!/usr/bin/env sh

# Stop at the first sign of trouble.
set -ex

# Install vim.
sudo pacman -S --noconfirm vim-minimal

# Create symlink for .vimrc.
ln -sf "$HOME/.env/vim/.vimrc" "$HOME/.vimrc"
