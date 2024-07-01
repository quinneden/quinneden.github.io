#!/usr/bin/env bash

FLAKE="nixos-hyprland-apple-silicon"
HOME="/mnt/home/quinn"

confirm() {
    echo -en "[y/n]: "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 0
    fi
}

copy_files() {
  echo -e "Creating folders:"
  echo -e "  - $HOME/Music"
  echo -e "  - $HOME/Documents"
  echo -e "  - $HOME/Pictures/wallpapers/others"
  mkdir -p $HOME/{Music,Documents}
  mkdir -p $HOME/Pictures/wallpapers/others
  sleep 0.2
  echo -e "Copying all wallpapers"
  cp -r /mnt/etc/nixos/wallpapers/wallpaper.png $HOME/Pictures/wallpapers
  cp -r /mnt/etc/nixos/wallpapers/otherWallpaper/catppuccin/* $HOME/Pictures/wallpapers/others/
  cp -r /mnt/etc/nixos/wallpapers/otherWallpaper/nixos/* $HOME/Pictures/wallpapers/others/
  cp -r /mnt/etc/nixos/wallpapers/otherWallpaper/others/* $HOME/Pictures/wallpapers/others/
  sleep 0.2
}

partition_disk() {
  echo "Creating partition..."
  sgdisk /dev/nvme0n1 -n 0:0 -s && sleep 0.2
  mkfs.btrfs -L nixos /dev/nvme0n1p5 && sleep 0.2
}

mount_disks() {
  echo "Mounting disks..."
  mount /dev/disk/by-label/nixos /mnt && sleep 0.2
  mkdir -p /mnt/boot && sleep 0.2
  mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /mnt/boot && sleep 0.2
}

init_etc() {
  echo "Cloning config..." && sleep 0.2
  mkdir -p /mnt/etc && sleep 0.2
  git clone https://github.com/quinneden/$FLAKE /mnt/etc/nixos && sleep 0.2
  nixos-generate-config --root /mnt --show-hardware-configuration | tee /mnt/etc/nixos/hosts/main/hardware.nix && sleep 0.2
}

init() {
  echo "Initiate?"
  confirm
  partition_disk &&
  mount_disks &&
  init_etc &&
  copy_files
}

install_system() {
  echo "Ready to install?"
  confirm
  systemctl restart systemd-timesyncd && sleep 0.2
  echo -e "\nInstalling...\n"
  test -e /tmp && mount -o remount,size=15G /tmp || true
  test -e /run/user/1000 && mount -o remount,size=15G /run/user/1000 || true
  test -e /run/user/0 && mount -o remount,size=15G /run/user/0 || true
  nix --extra-experimental-features 'nix-command flakes' flake update /mnt/etc/nixos && sleep 0.2
  nixos-install --flake /mnt/etc/nixos#main --impure -j4
}

init && install_system && exit 0
