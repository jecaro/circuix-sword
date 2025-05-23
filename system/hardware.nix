nixos-hardware: rpifirmware:
{ config, lib, pkgs, ... }:
{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-3
  ];

  boot = {
    # Timeout before the loader boots the default menu item
    loader.timeout = 1;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # Required for GPIO to work
    kernelParams = [ "iomem=relaxed" ];
    # Turn off the buildin audio module. The speaker uses a MicroII USB sound
    # card.
    blacklistedKernelModules = [ "snd_bcm2835" ];
    # The audio modules with the volume fix
    extraModulePackages = [
      (pkgs.callPackage ./snd-usb-audio-modules {
        # Make sure the module targets the same kernel the system
        # is using
        kernel = config.boot.kernelPackages.kernel;
      })
    ];
  };

  hardware = {
    # The wifi firmware
    firmware = [ pkgs.rtl8723-firmware ];

    # Enable opengl for SDL2 to use
    graphics.enable = true;

    deviceTree = {
      enable = true;
      # That's the device tree we generate with the overlay applied. If we dont
      # set the device tree name here the kernel picks the one in the FIRMWARE
      # partition which does not have the overlay applied.
      name = "broadcom/bcm2710-rpi-cm3.dtb";

      # Only keep the one for the CM3
      filter = lib.mkDefault "bcm2710-rpi-cm3.dtb";

      # Adapted from: https://github.com/NixOS/nixpkgs/issues/320557#issuecomment-2176067772
      overlays = map
        (name: {
          inherit name;

          dtsFile = pkgs.runCommand "dtoverlay-${name}" { } ''
            cd ${rpifirmware}/arch/arm/boot/dts/overlays
            ${pkgs.ovmerge}/bin/ovmerge ${name} | sed "s/brcm,bcm2835/brcm,bcm2837/g" > $out
          '';
        })
        [
          # The wifi chip needs the sdio overlay
          "sdio-overlay.dts,poll_once=false"
          # For safe shutdown
          "gpio-poweroff-overlay.dts,gpiopin=39,active_low=\"y\""
          # Hardware acceleration for SDL2
          "vc4-kms-v3d-overlay.dts,nohdmi"
          # Specific settings for the screen
          # see https://forums.raspberrypi.com/viewtopic.php?t=363239
          "vc4-kms-dpi-generic-overlay.dts,hactive=320,hfp=20,hsync=30,hbp=38,hsync-invert,vactive=240,vfp=4,vsync=3,vbp=10,vsync-invert,clock-frequency=9600000,bus-format=0x1009,de-invert,rotate=180"
        ];
    };
  };

}

