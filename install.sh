#!/usr/bin/env sh
set -ex

# Install dependencies.
sudo pacman -S --noconfirm wget git openssh

# Clone the repository if this is our first time.
if [ ! -e "$HOME/.env" ]; then
    git clone git@github.com:erkl/env.git "$HOME/.env"
fi

# Run the setup script.
cd "$HOME/.env"

for script in "$HOME"/.env/*/install.sh; do
  sh "$script"
done

cd -
