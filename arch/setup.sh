#!/usr/bin/env sh
set -ex

# Upgrade existing packages, then make sure we have everything we need.
sudo pacman -Syu

sudo pacman -S --needed --noconfirm  \
    libva                            \
    libva-intel-driver               \
    mesa-libgl                       \
    xf86-video-intel                 \
                                     \
    curl                             \
    openssh                          \
    openssl                          \
    tmux                             \
    vim-minimal                      \
    wget                             \
    zsh                              \

# Decrypt SSH keys.
mkdir -p "${HOME}/.ssh"

openssl enc -aes-256-cbc -d -base64 -in "${HOME}/.env/keys/id_rsa.enc" -out "${HOME}/.ssh/id_rsa"
openssl enc -aes-256-cbc -d -base64 -in "${HOME}/.env/keys/id_rsa.pub.enc" -out "${HOME}/.ssh/id_rsa.pub"

chmod 0700 "${HOME}/.ssh"
chmod 0644 "${HOME}/.ssh/id_rsa.pub"
chmod 0600 "${HOME}/.ssh/id_rsa"

# Link the authorized_keys file to id_rsa.
ln -sf "${HOME}/.ssh/id_rsa.pub" "${HOME}/.ssh/authorized_keys"

# Create a sensible sshd_config file (the weird use of tee is necessary
# because sudo doesn't apply to output redirection).
sudo tee /etc/ssh/sshd_config > /dev/null <<EOF
AddressFamily any
Port 22
Protocol 2
StrictModes yes

# Disable root login.
PermitRootLogin no

# Disable passwords.
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no

# Hide annoying messages.
PrintMotd no
Banner no
EOF

# Start the SSH daemon.
sudo systemctl enable sshd.service
sudo systemctl start sshd.service

# Switch to zsh.
chsh -s /usr/bin/zsh

# Move into the ~/.env directory.
cd "${HOME}/.env"

# The bootstrap script sets the repository's origin using HTTPS;
# here we change it to SSL instead.
git remote set-url origin git@github.com:erkl/env.git

# Return to the previous directory.
cd -
