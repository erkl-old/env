#!/usr/bin/env sh

# Stop at the first sign of trouble.
set -ex

# Include all rc.zsh scripts.
for rc in $(find "$HOME/.env/*/rc.zsh" 2>/dev/null); do
  source "$rc"
done

