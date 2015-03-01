#!/usr/bin/env sh

# Device configuration.
CONF_DEVICE=/dev/sda
CONF_BOOT_PARTITION=1
CONF_LUKS_PARTITION=2

# LUKS configuration.
CONF_LUKS_DMNAME=crypt
CONF_LUKS_PASSPHRASE=?

# LVM configuration.
CONF_LVM_VGNAME=system
CONF_LVM_ROOT_SIZE=8G
CONF_LVM_VAR_SIZE=6G
CONF_LVM_SWAP_SIZE=2G

# Basic system/user configuration.
CONF_HOSTNAME=?
CONF_USERNAME=erkl
CONF_PASSWORD=?
CONF_KEYMAP=uk
CONF_TIMEZONE=Europe/London

# Ask for confirmation before starting.
printf "\n"
printf "  ##  Did you remember to configure this script?\n"
printf "  ##  If so, press enter to begin.\n"
printf "\n"

read

# Stop at the first sign of trouble.
set -ex

# Turn the second partition into an encrypted LUKS container.
cryptsetup luksFormat "$CONF_DEVICE$CONF_LUKS_PARTITION" <<EOF
$CONF_LUKS_PASSPHRASE
EOF

cryptsetup luksOpen "$CONF_DEVICE$CONF_LUKS_PARTITION" "$CONF_LUKS_DMNAME" <<EOF
$CONF_LUKS_PASSPHRASE
EOF

# Create LVM volumes.
pvcreate "/dev/mapper/$CONF_LUKS_DMNAME"
vgcreate system "/dev/mapper/$CONF_LUKS_DMNAME"

lvcreate system -n swap -L "$CONF_LVM_SWAP_SIZE"
lvcreate system -n root -L "$CONF_LVM_ROOT_SIZE"
lvcreate system -n var  -L "$CONF_LVM_VAR_SIZE"
lvcreate system -n home -l 100%FREE

# Prepare filesystems.
mkfs.ext2 "$CONF_DEVICE$CONF_BOOT_PARTITION"

mkfs.ext4 "/dev/mapper/$CONF_LVM_VGNAME-root"
mkfs.ext4 "/dev/mapper/$CONF_LVM_VGNAME-var"
mkfs.ext4 "/dev/mapper/$CONF_LVM_VGNAME-home"

# Mount the filesystems.
mount "/dev/mapper/$CONF_LVM_VGNAME-root" /mnt

mkdir /mnt/{boot,var,home}

mount "$CONF_DEVICE$CONF_BOOT_PARTITION" /mnt/boot
mount "/dev/mapper/$CONF_LVM_VGNAME-var" /mnt/var
mount "/dev/mapper/$CONF_LVM_VGNAME-home" /mnt/home

# Initialize our swap partition.
mkswap "/dev/mapper/$CONF_LVM_VGNAME-swap"
swapon "/dev/mapper/$CONF_LVM_VGNAME-swap"

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
arch-chroot /mnt /bin/bash -c "useradd -m -G wheel -s /bin/bash '$CONF_USERNAME'"
arch-chroot /mnt /bin/bash -c "passwd '$CONF_USERNAME'" <<EOF
$CONF_PASSWORD
$CONF_PASSWORD
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
$CONF_HOSTNAME
EOF

cat > /mnt/etc/hosts <<EOF
#<ip-address>   <hostname.domain.org>   <hostname>
127.0.0.1       localhost.localdomain   localhost    $CONF_HOSTNAME
::1             localhost.localdomain   localhost    $CONF_HOSTNAME
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
KEYMAP=$CONF_KEYMAP
EOF

# Select timezone.
arch-chroot /mnt /bin/bash -c "ln -s -f /usr/share/zoneinfo/$CONF_TIMEZONE /etc/localtime"

# Base the hardware clock on UTC.
arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"

# Add "keymap", "encrypt", "lvm" and "resume" hooks, then build the initial
# ramdisk environment.
sed -e 's/^\(HOOKS=".*\) \(filesystems .*"\)$/\1 keymap encrypt lvm2 resume \2/' -i /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"

# Install GRUB.
sed -e 's/^GRUB_CMDLINE_LINUX=.*$/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda2:crypt resume=\/dev\/mapper\/system-swap"/' -i /mnt/etc/default/grub
sed -e 's/^GRUB_GFXMODE=.*$/GRUB_GFXMODE=800x600,600x480/' -i /mnt/etc/default/grub
arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc --recheck $CONF_DEVICE"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

# Unmount the new system.
umount -R /mnt
