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

      # Legacy config for the display. Allow the screen to turn on after a
      # couple of seconds, then KMS takes over.
      # See: https://forums.raspberrypi.com/viewtopic.php?t=386588
      gpio = "0-21=a2";
      display_lcd_rotate = 2;
      enable_dpi_lcd = 1;
      dpi_group = 2;
      dpi_mode = 87;
      dpi_output_format = 24597;
      dpi_timings = "320 1 20 30 38 240 1 4 3 10 0 0 0 60 0 9600000 1";
    };
  };

  boot.supportedFilesystems = {
    # Disable building zfs, it takes a long time
    zfs = lib.mkForce false;
    # cifs pull python dependencies
    cifs = lib.mkForce false;
  };
}

