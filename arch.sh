#!/usr/bin/env sh

# Basic configuration.
printf "\n    Hostname:\n"
while [ -z "${CONF_HOSTNAME}" ]; do
  printf "      > "; read CONF_HOSTNAME
done

printf "\n    Username:\n"
while [ -z "${CONF_USERNAME}" ]; do
  printf "      > "; read CONF_USERNAME
done

printf "\n    Password:\n"
while [ -z "${CONF_PASSWORD}" ]; do
  printf "      > "; read -s CONF_PASSWORD; printf "\n"
done

# Location configuration.
printf "\n    Keymap (e.g. \"uk\"):\n"
while [ -z "${CONF_KEYMAP}" ]; do
  printf "      > "; read CONF_KEYMAP
done

printf "\n    Timezone (e.g. \"Europe/London\"):\n"
while [ -z "${CONF_TIMEZONE}" ]; do
  printf "      > "; read CONF_TIMEZONE
done

# LUKS configuration.
printf "\n    LUKS device (e.g. \"/dev/sda\"):\n"
while [ -z "${CONF_DEVICE}" ]; do
  printf "      > "; read CONF_DEVICE
done

printf "\n    LUKS volume name (e.g. \"crypt\"):\n"
while [ -z "${CONF_DMNAME}" ]; do
  printf "      > "; read CONF_DMNAME
done

printf "\n    LUKS password:\n"
while [ -z "${CONF_LUKS_PASSPHRASE}" ]; do
  printf "      > "; read -s CONF_LUKS_PASSPHRASE; printf "\n"
done

# LVM configuration.
printf "\n    LVM volume name (e.g. \"system\"):\n"
while [ -z "${CONF_VGNAME}" ]; do
  printf "      > "; read CONF_VGNAME
done

printf "\n    / partition size (e.g. \"8G\"):\n"
while [ -z "${CONF_ROOT_SIZE}" ]; do
  printf "      > "; read CONF_ROOT_SIZE
done

printf "\n    /var partition size (e.g. \"4G\"):\n"
while [ -z "${CONF_VAR_SIZE}" ]; do
  printf "      > "; read CONF_VAR_SIZE
done

printf "\n    Swap partition size (e.g. \"1G\"):\n"
while [ -z "${CONF_SWAP_SIZE}" ]; do
  printf "      > "; read CONF_SWAP_SIZE
done

# Ask for confirmation before starting.
printf "\n -- Ready, press any key to begin. --\n"
read

# Stop at the first sign of trouble.
set -ex

# Write the new MBR partition table.
fdisk "${CONF_DEVICE}" <<EOF
o
n
p
1

+256M
n
p
2


t
2
8e
a
1
w
EOF

# Turn the second partition into an encrypted LUKS container.
cryptsetup luksFormat "${CONF_DEVICE}2" <<EOF
${CONF_LUKS_PASSPHRASE}
EOF

cryptsetup luksOpen "${CONF_DEVICE}2" "${CONF_DMNAME}" <<EOF
${CONF_LUKS_PASSPHRASE}
EOF

# Create LVM volumes.
pvcreate "/dev/mapper/${CONF_DMNAME}"
vgcreate system "/dev/mapper/${CONF_DMNAME}"

lvcreate system -n swap -L "${CONF_SWAP_SIZE}"
lvcreate system -n root -L "${CONF_ROOT_SIZE}"
lvcreate system -n var  -L "${CONF_VAR_SIZE}"
lvcreate system -n home -l 100%FREE

# Prepare filesystems.
mkfs.ext2 "${CONF_DEVICE}1"

mkfs.ext4 "/dev/mapper/${CONF_VGNAME}-root"
mkfs.ext4 "/dev/mapper/${CONF_VGNAME}-var"
mkfs.ext4 "/dev/mapper/${CONF_VGNAME}-home"

# Mount the filesystems.
mount "/dev/mapper/${CONF_VGNAME}-root" /mnt

mkdir /mnt/{boot,var,home}

mount "${CONF_DEVICE}1" /mnt/boot
mount "/dev/mapper/${CONF_VGNAME}-var" /mnt/var
mount "/dev/mapper/${CONF_VGNAME}-home" /mnt/home

# Initialize our swap partition.
mkswap "/dev/mapper/${CONF_VGNAME}-swap"
swapon "/dev/mapper/${CONF_VGNAME}-swap"

# Use UK mirrors.
cat > /etc/pacman.d/mirrorlist <<EOF
# United Kingdom
Server = http://mirror.bytemark.co.uk/archlinux/\$repo/os/\$arch
Server = http://mirror.cinosure.com/archlinux/\$repo/os/\$arch
Server = http://mirrors.manchester.m247.com/arch-linux/\$repo/os/\$arch
Server = http://www.mirrorservice.org/sites/ftp.archlinux.org/\$repo/os/\$arch
Server = http://arch.serverspace.co.uk/arch/\$repo/os/\$arch
Server = http://archlinux.mirrors.uk2.net/\$repo/os/\$arch
EOF

# At last, install the base system.
pacstrap /mnt base base-devel grub-bios ifplugd wpa_actiond

# Generate /etc/fstab.
genfstab -p /mnt > /mnt/etc/fstab

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

# Set hostname.
cat > /mnt/etc/hostname <<EOF
${CONF_HOSTNAME}
EOF

cat > /mnt/etc/hosts <<EOF
#<ip-address>   <hostname.domain.org>   <hostname>
127.0.0.1       localhost.localdomain   localhost    ${CONF_HOSTNAME}
::1             localhost.localdomain   localhost
EOF

# Configure locale.
cat > /mnt/etc/locale.conf <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
EOF

cat > /mnt/etc/locale.gen <<EOF
en_US.UTF-8 UTF-8
EOF

locale-gen

# Set keyboard layout.
cat > /mnt/etc/vconsole.conf <<EOF
KEYMAP=${CONF_KEYMAP}
EOF

# Select timezone.
arch-chroot /mnt /bin/bash -c "ln -s -f /usr/share/zoneinfo/${CONF_TIMEZONE} /etc/localtime"

# Base the hardware clock on UTC.
arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"

# Add "keymap", "encrypt", "lvm" and "resume" hooks, then build the initial
# ramdisk environment.
sed -e 's/^\(HOOKS=".*\) \(filesystems .*"\)$/\1 keymap encrypt lvm2 resume \2/' -i /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"

# Install GRUB.
sed -e 's/^GRUB_CMDLINE_LINUX=.*$/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda2:crypt resume=\/dev\/mapper\/system-swap"/' -i /mnt/etc/default/grub
sed -e 's/^GRUB_GFXMODE=.*$/GRUB_GFXMODE=800x600,600x480/' -i /mnt/etc/default/grub
arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc --recheck ${CONF_DEVICE}"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

# Unmount the new system.
umount -R /mnt
