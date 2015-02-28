#!/usr/bin/env sh
set -ex

# Move into the .env directory.
cd "$HOME/.env"

# Run all setup scripts.
for script in "$HOME"/.env/*/install.sh; do
  sh "$script"
done

# Go back to the last directory.
cd -
