#!/usr/bin/env bash

confirm() {
    echo -en "[${GREEN}y${NORMAL}/${RED}n${NORMAL}]: "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 0
    fi
}

set -e

sgdisk /dev/nvme0n1 -n 0:0 -s && sleep 0.2

mkfs.ext4 -L nixos /dev/nvme0n1p5 && sleep 0.2

mount /dev/disk/by-label/nixos /mnt && sleep 0.2

mkdir -p /mnt/boot && sleep 0.2

mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /mnt/boot && sleep 0.2

nixos-generate-config --root /mnt && sleep 0.2

cp -r /etc/nixos/apple-silicon-support /mnt/etc/nixos && sleep 0.2

chmod -R +w /mnt/etc/nixos

mkdir -p /mnt/etc/nixos/firmware && sleep 0.2

cp /mnt/boot/asahi/{kernelcache*,all_firmware.tar.gz} /mnt/etc/nixos/firmware && sleep 0.2

cat > /mnt/etc/nixos/configuration.nix <<EOF
{ config, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  hardware.asahi.peripheralFirmwareDirectory = ./firmware;

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  security = {
    sudo.wheelNeedsPassword = false;
  };

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.root.password = "nixos";

  users.users.quinn = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    gh
    git
    micro
    ripgrep
  ];

  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
EOF

systemctl restart systemd-timesyncd && sleep 0.2

echo -en "Ready to install?"
confirm

echo -e "\nInstalling...\n"
nixos-install --root /mnt
