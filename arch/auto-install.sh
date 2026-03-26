#!/bin/bash

# ====================== User-configurable variables ======================
DISK="/dev/sda"               # Target disk, e.g., /dev/sda or /dev/nvme0n1
HOSTNAME="archlinux"          # Hostname
ROOT_PASSWORD="root"          # Root password (strongly recommended to change after installation)
TIMEZONE="Asia/Shanghai"      # Timezone
LOCALE="en_US.UTF-8"          # System language (English, Chinese fonts will be installed separately)
# =========================================================================

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (you are already root in Arch live environment)"
    exit 1
fi

# Confirm target disk
echo "Will install to $DISK. All data on this disk will be erased!"
read -p "Continue? (y/N) " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 1
fi

# Check UEFI mode
UEFI_MODE=false
if [ -d /sys/firmware/efi ]; then
    UEFI_MODE=true
    echo "UEFI mode detected"
else
    echo "BIOS mode (Legacy) detected. This script only supports UEFI mode"
    exit 1
fi

# Connect to network (assuming wired connection is already active)
echo "Testing network connection..."
ping -c 3 archlinux.org > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Network not connected. Please configure network manually before running this script"
    exit 1
fi

# Sync time
timedatectl set-ntp true
echo "Time synchronized"

# ==================== Set up Chinese mirror for faster downloads ====================
echo "Configuring pacman mirror to Tsinghua (China) for faster downloads..."
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
cat > /etc/pacman.d/mirrorlist << EOF
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
EOF
pacman -Sy
# ===================================================================================

# Partitioning (UEFI + GPT)
echo "Partitioning $DISK ..."
parted -s "$DISK" mklabel gpt \
    mkpart primary fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary ext4 513MiB 100%

# Wait for partition table update
sleep 2

# Get partition names (compatible with NVMe and SATA)
if [[ "$DISK" == *"nvme"* ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 -F "$ROOT_PART"

# Mount partitions
echo "Mounting partitions..."
mount "$ROOT_PART" /mnt
mount --mkdir "$EFI_PART" /mnt/boot

# Install base system
echo "Installing base system..."
pacstrap -K /mnt base linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Enter new system for configuration
arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Set locale
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Install Chinese fonts (lightweight wqy-microhei)
pacman -S --noconfirm wqy-microhei
# For more comprehensive CJK support, use noto-fonts-cjk instead:
# pacman -S --noconfirm noto-fonts-cjk

# Install bootloader
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install NetworkManager for easy network management after installation
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

EOF

# Clean up and reboot hint
umount -R /mnt
echo "Installation complete! You can now reboot: reboot"
