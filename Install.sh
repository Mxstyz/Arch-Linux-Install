wipefs -a /dev/sda
parted /dev/sda mklabel gpt
parted /dev/sda mkpart primary fat32 1MB 501MB
parted /dev/sda set 1 boot on
parted /dev/sda mkpart primary ext4 501MB 100%
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 -F /dev/sda2
mount /dev/sda2 /mnt
mount --mkdir /dev/sda1 /mnt/boot
pacstrap -K /mnt base linux linux-firmware networkmanager grub efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf
echo "ArchVM" >> /etc/hostname
locale-gen
systemctl enable NetworkManager
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
exit
EOF
chroot /mnt passwd
