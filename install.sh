#!/usr/bin/env sh
set -ex

# Install dependencies.
sudo pacman -S --noconfirm wget git openssh

# Download and decrypt the public and private keys.
if [ ! -e "$HOME/.ssh/id_rsa" -o ! -e "$HOME/.ssh/id_rsa.pub" ]; then
    mkdir -p "$HOME/.ssh"
    wget -qO - https://github.com/erkl/env/raw/master/ssh/keys/id_rsa.encrypted | openssl enc -aes-256-cbc -d > "$HOME/.ssh/id_rsa"
    wget -qO - https://github.com/erkl/env/raw/master/ssh/keys/id_rsa.pub.encrypted | openssl enc -aes-256-cbc -d > "$HOME/.ssh/id_rsa.pub"

    chmod 0700 "$HOME/.ssh"
    chmod 0600 "$HOME/.ssh/id_rsa"
    chmod 0644 "$HOME/.ssh/id_rsa.pub"
fi

# Clone the whole repository.
if [ ! -e "$HOME/.env" ]; then
    git clone git@github.com:erkl/env.git "$HOME/.env"
fi

# Run the setup script.
cd "$HOME/.env"

for script in "$HOME"/.env/*/install.sh; do
  sh "$script"
done

cd -
