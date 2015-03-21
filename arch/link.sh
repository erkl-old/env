#!/usr/bin/env sh
set -ex

# Symlink all dotfiles into the home directory.
for file in $(find -mindepth 1 "${HOME}/.env/dotfiles"); do
  base=$(basename "${file}")
  ln -sf "${HOME}/.env/dotfiles/${base}" "${HOME}/${file}"
fi
