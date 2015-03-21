#!/usr/bin/env sh

# Configuration variables.
CONF_DEVICE="/dev/sda"

CONF_ROOT_SIZE="16G"
CONF_VAR_SIZE="8G"
CONF_SWAP_SIZE="2G"

CONF_TIMEZONE="Europe/London"
CONF_KEYMAP="uk"

# Prompt for the hostname.
while [ -z "${CONF_HOSTNAME}" ]; do
  printf "Hostname: "
  read CONF_HOSTNAME
done

# Prompt for a LUKS passphrase.
while [ -z "$CONF_PASSPHRASE" ]; do
  printf "LUKS passphrase: "
  read -s CONF_PASSPHRASE
  printf "\n"
done

# Prompt for user credentials.
while [ -z "${CONF_USERNAME}" ]; do
  printf "Username: "
  read CONF_USERNAME
done

while [ -z "${CONF_PASSWORD}" ]; do
  printf "Password: "
  read -s CONF_PASSWORD
  printf "\n"
done

# Stop at the first sign of trouble.
set -ex

# Replace the device's current partition layout with our own: a 256MB boot
# partition, and a partition using all remaining space to use for LUKS.
fdisk "${CONF_DEVICE}" <<EOF
o
n
p
1

+256M
n
p
2


a
1
t
2
8e
w
EOF

# Setup LUKS encryption on the device's second partition.
cryptsetup luksFormat "${CONF_DEVICE}2" <<EOF
${CONF_PASSPHRASE}
EOF

cryptsetup luksOpen "${CONF_DEVICE}2" "crypt" <<EOF
${CONF_PASSPHRASE}
EOF

# Create a logical volume using LVM, on top of our LUKS partition.
pvcreate "/dev/mapper/crypt"
vgcreate lvm "/dev/mapper/crypt"

lvcreate lvm -n swap -L "${CONF_SWAP_SIZE}"
lvcreate lvm -n root -L "${CONF_ROOT_SIZE}"
lvcreate lvm -n var  -L "${CONF_VAR_SIZE}"
lvcreate lvm -n home -l 100%FREE

# Initialize file systems.
mkfs.ext2 -F "${CONF_DEVICE}1"
mkfs.ext4 -F "/dev/mapper/lvm-root"
mkfs.ext4 -F "/dev/mapper/lvm-var"
mkfs.ext4 -F "/dev/mapper/lvm-home"

# Mount partitions.
mount "/dev/mapper/lvm-root" /mnt
mkdir /mnt/var
mount "/dev/mapper/lvm-var" /mnt/var
mkdir /mnt/home
mount "/dev/mapper/lvm-home" /mnt/home
mkdir /mnt/boot
mount "${CONF_DEVICE}1" /mnt/boot

# Initialize swap space.
mkswap "/dev/mapper/lvm-swap"
swapon "/dev/mapper/lvm-swap"

# Save a list of UK mirrors taken from:
#   https://www.archlinux.org/mirrorlist/?country=GB&protocol=http&ip_version=4
cat > /etc/pacman.d/mirrorlist <<EOF
# United Kingdom
Server = http://mirror.bytemark.co.uk/archlinux/\$repo/os/\$arch
Server = http://mirror.cinosure.com/archlinux/\$repo/os/\$arch
Server = http://mirrors.manchester.m247.com/arch-linux/\$repo/os/\$arch
Server = http://www.mirrorservice.org/sites/ftp.archlinux.org/\$repo/os/\$arch
Server = http://arch.serverspace.co.uk/arch/\$repo/os/\$arch
Server = http://archlinux.mirrors.uk2.net/\$repo/os/\$arch
EOF

# Bootstrap the base system.
pacstrap /mnt base base-devel grub-bios ifplugd wpa_actiond git

# Generate /etc/fstab.
genfstab -p /mnt > /mnt/etc/fstab

# Set hostname.
cat > /mnt/etc/hostname <<EOF
${CONF_HOSTNAME}
EOF

sudo cat > /etc/hosts <<EOF
#<ip-address>   <hostname.domain.org>   <hostname>   ...
127.0.0.1       localhost.localdomain   localhost    ${CONF_HOSTNAME}
::1             localhost.localdomain   localhost    ${CONF_HOSTNAME}
EOF

# Create the primary user account.
arch-chroot /mnt /bin/bash -c "useradd -m -G wheel -s /bin/bash '${CONF_USERNAME}'"
arch-chroot /mnt /bin/bash -c "passwd '${CONF_USERNAME}'" <<EOF
${CONF_PASSWORD}
${CONF_PASSWORD}
EOF

# Add the wheel group to /etc/sudoers.
cat > /mnt/etc/sudoers <<EOF
root    ALL=(ALL) ALL
%wheel  ALL=(ALL) ALL

#includedir /etc/sudoers.d
EOF

# Disable root login.
arch-chroot /mnt /bin/bash -c "passwd -l root"

# Configure locale.
cat > /mnt/etc/locale.conf <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
EOF

cat > /mnt/etc/locale.gen <<EOF
en_US.UTF-8 UTF-8
EOF

arch-chroot /mnt /bin/bash -c "locale-gen"

# Set keyboard layout.
cat > /mnt/etc/vconsole.conf <<EOF
KEYMAP=${CONF_KEYMAP}
EOF

# Add "keymap", "encrypt", "lvm" and "resume" hooks, then build the initial
# ramdisk environment.
sed -e 's|^\(HOOKS=".*\) \(filesystems .*"\)$|\1 keymap encrypt lvm2 resume \2|' -i /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"

# Install GRUB.
sed -e 's|^GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX="cryptdevice='"${CONF_DEVICE}"'2:crypt resume=/dev/mapper/lvm-swap"|' -i /mnt/etc/default/grub
sed -e 's|^GRUB_GFXMODE=.*$|GRUB_GFXMODE=800x600,600x480|' -i /mnt/etc/default/grub
arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc --recheck ${CONF_DEVICE}"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

# Clone the repository into the user's home folder.
arch-chroot /mnt /bin/bash -c "sudo -u ${CONF_USERNAME} git clone 'https://github.com/erkl/env.git' /home/${CONF_USERNAME}/.env"

# Unmount the new system.
umount -R /mnt
