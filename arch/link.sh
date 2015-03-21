#!/usr/bin/env sh
set -ex

# Symlink all dotfiles into the home directory.
for file in $(find "${HOME}/.env/dotfiles" -mindepth 1); do
  base=$(basename "${file}")
  ln -sf "${file}" "${HOME}/${base}"
done
