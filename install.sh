#!/usr/bin/env sh
set -ex

# Run all install scripts.
for script in $HOME/.env/*/install.sh; do
  sh "$script"
done
