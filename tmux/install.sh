#!/usr/bin/env sh
set -ex

# Install tmux.
sudo pacman -S --noconfirm tmux

# Create symlink for .tmux.conf.
ln -sf "$HOME/.env/tmux/.tmux.conf" "$HOME/.tmux.conf"
