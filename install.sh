#!/usr/bin/env sh

# Basic configuration.
CONF_DEVICE="/dev/sda"
CONF_DMNAME="crypt"
CONF_VGNAME="system"

CONF_LANG="en_GB"
CONF_LANGUAGE="en_GB:en_US:en"
CONF_KEYMAP="uk"
CONF_TIMEZONE="Europe/London"

CONF_ROOT_SIZE="16G"
CONF_VAR_SIZE="8G"
CONF_SWAP_SIZE="4G"


# Display the obligatory warning.
printf "#######################################################\n"
printf "##                                                   ##\n"
printf "##               --     WARNING     --               ##\n"
printf "##                                                   ##\n"
printf "##    This command will erase all your cat gifs.     ##\n"
printf "##       (Also everything else on /dev/sda).         ##\n"
printf "##                                                   ##\n"
printf "#######################################################\n"
printf "\n"


# Read configuration which is likely to change between machines.
while [ -z "${CONF_HOSTNAME}" ]; do
  printf "   Hostname: "
  read CONF_HOSTNAME
done

while [ -z "${CONF_USERNAME}" ]; do
  printf "   User: "
  read CONF_USERNAME
done

while [ -z "${CONF_PASSWORD}" ]; do
  printf "   Password: "
  read -s CONF_PASSWORD
  printf "\n"
done

while [ -z "${CONF_LUKS_PASSPHRASE}" ]; do
  printf "   Encryption key: "
  read -s CONF_LUKS_PASSPHRASE
  printf "\n"
done

printf "\n"


# Stop at the first sign of trouble.
set -e
set -x


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
pacstrap /mnt base base-devel grub-bios


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
LANG=${CONF_LANG}.UTF-8
LANGUAGE=${CONF_LANGUAGE}
EOF

cat > /mnt/etc/locale.gen <<EOF
${CONF_LANG}.UTF-8 UTF-8
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
sed -e 's/^\(HOOKS=".*\) \(filesystems.*"\)/\1 keymap encrypt lvm2 resume \2/' -i /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"


# Install GRUB.
sed -e 's/^\(GRUB_CMDLINE_LINUX\)=.*$/\1="\2="cryptdevice=\/dev\/sda2:crypt resume=\/dev\/mapper\/system-swap"/' -i /mnt/etc/default/grub
arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc --recheck ${CONF_DEVICE}"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"


# Unmount the new system.
umount -R /mnt
