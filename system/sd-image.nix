{ nixpkgs, nixos-pi-zero-2-src }:
{ config, lib, pkgs, ... }:
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    (nixos-pi-zero-2-src + "/sd-image.nix")
  ];

  sdImage = {
    # Dont compress the image its very time consuming
    compressImage = false;
    # Handled by nixos-pi-zero-2, creates config.txt file in /boot/firmware
    extraFirmwareConfig = {
      # Some settings from the orignal config.txt
      gpu_mem_256 = 128;
      gpu_mem_512 = 256;
      gpu_mem_1024 = 256;
      overscan_scale = 1;
    };
  };

  # Disable building zfs, it takes a long time
  boot.supportedFilesystems.zfs = lib.mkForce false;
}

