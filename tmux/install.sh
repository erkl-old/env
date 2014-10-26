#!/usr/bin/env sh

# Stop at the first sign of trouble.
set -ex

# Install tmux.
sudo pacman -S --noconfirm tmux

# Create symlink for .tmux.conf.
ln -sf "$HOME/.env/tmux/.tmux.conf" "$HOME/.tmux.conf"
