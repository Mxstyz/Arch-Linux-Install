#!/bin/bash

# Execute lsblk command to list available drives
lsblk -d -o NAME,SIZE,MODEL

# Ask the user to choose a drive
read -p "Please enter the name of the drive you want to use (e.g., sda, sdb): " drive_name

# Update the script with the chosen drive name
drive="/dev/$drive_name"

# Wipe the drive
wipefs -a "$drive"

# Create GPT partition table
parted "$drive" mklabel gpt

# Create primary partitions
parted "$drive" mkpart primary fat32 1MB 501MB
parted "$drive" set 1 boot on
parted "$drive" mkpart primary ext4 501MB 100%

# Format partitions
mkfs.fat -F32 "${drive}1"
mkfs.ext4 "${drive}2"

# Mount partitions
mount "${drive}2" /mnt
mkdir -p /mnt/boot
mount "${drive}1" /mnt/boot

# Install base system and necessary packages
pacstrap -K /mnt base linux linux-firmware networkmanager grub efibootmgr

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Ask the user for a hostname
read -p "Please enter a hostname for the system: " hostname

# Chroot into the installed system
arch-chroot /mnt /bin/bash <<EOF
  ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
  hwclock --systohc
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  echo "LANG=en_US.UTF-8" > /etc/locale.conf
  echo "KEYMAP=uk" > /etc/vconsole.conf
  echo "$hostname" > /etc/hostname
  locale-gen
  systemctl enable NetworkManager
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
  exit
EOF

# Set the password for the installed system
chroot /mnt passwd
