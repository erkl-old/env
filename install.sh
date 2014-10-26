#!/usr/bin/env sh

# Stop at the first sign of trouble.
set -ex

# Run all install scripts.
for script in $HOME/.env/*/install.sh; do
  sh "$script"
done
