nixos-pi-zero-2-src:
{ config, lib, modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    (nixos-pi-zero-2-src + "/sd-image.nix")
  ];

  sdImage = {
    # Compressing is slow. Turn this off if you need to iterate on the image.
    compressImage = true;

    # Handled by nixos-pi-zero-2, creates config.txt file in /boot/firmware
    extraFirmwareConfig = {
      # Some settings from the orignal config.txt
      gpu_mem_256 = 128;
      gpu_mem_512 = 256;
      gpu_mem_1024 = 256;
      overscan_scale = 1;
    };
  };

  boot.supportedFilesystems = {
    # Disable building zfs, it takes a long time
    zfs = lib.mkForce false;
    # cifs pull python dependencies
    cifs = lib.mkForce false;
  };
}

