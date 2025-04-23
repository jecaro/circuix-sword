{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # The sources of the overlays are here:
    # https://github.com/raspberrypi/linux/blob/rpi-6.12.y/arch/arm/boot/dts/overlays
    rpifirmware = {
      url = "github:raspberrypi/linux/rpi-6.12.y";
      flake = false;
    };

    ovmerge-src = {
      type = "github";
      owner = "raspberrypi";
      repo = "utils";
      dir = "ovmerge";
      flake = false;
    };

    nixos-pi-zero-2-src = {
      url = "github:plmercereau/nixos-pi-zero-2";
      flake = false;
    };
  };

  outputs =
    { nixos-hardware
    , nixos-pi-zero-2-src
    , nixpkgs
    , ovmerge-src
    , rpifirmware
    , ...
    }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations.circuix = lib.nixosSystem {
        system = "aarch64-linux";

        modules = [
          ({ config, pkgs, ... }:
            {
              imports = [
                "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
                nixos-hardware.nixosModules.raspberry-pi-3
                (nixos-pi-zero-2-src + "/sd-image.nix")
              ];

              nixpkgs = {
                overlays = [
                  (import ./overlays/SDL2.nix)
                  (import ./overlays/cs-hud)
                  (import ./overlays/ovmerge.nix ovmerge-src)
                  (import ./overlays/retroarch.nix)
                  (import ./overlays/wiringpi)
                ];

                config = {
                  # For fbneo
                  allowUnfree = true;
                  # For emulationstation
                  permittedInsecurePackages = [
                    "freeimage-unstable-2021-11-01"
                  ];
                };
              };

              # Dont compress the image its very time consuming
              sdImage = {
                compressImage = false;
                extraFirmwareConfig = {
                  # Some settings from the orignal config.txt
                  gpu_mem_256 = 128;
                  gpu_mem_512 = 256;
                  gpu_mem_1024 = 256;
                  overscan_scale = 1;
                };
              };

              boot = {
                # Disable building zfs, it takes a long time
                supportedFilesystems.zfs = lib.mkForce false;
                initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
                # Required for GPIO to work
                kernelParams = [ "iomem=relaxed" ];
              };

              console.keyMap = "fr";
              i18n.defaultLocale = "en_US.UTF-8";

              hardware = {
                # To include the wifi firmware
                enableRedistributableFirmware = true;

                # Enable opengl for SDL2 to use
                graphics.enable = true;

                deviceTree = {
                  enable = true;
                  # That's the device tree we generate with the overlay
                  # applied. If we dont set the device tree name here the
                  # kernel picks the one in the FIRMWARE partition which does not 
                  # have the overlay applied.
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
                      "vc4-kms-dpi-generic-overlay.dts,hactive=320,hfp=20,hsync=30,hbp=38,hsync-invert,vactive=240,vfp=4,vsync=3,vbp=10,vsync-invert,clock-frequency=9600000,bus-format=0x1023,de-invert,rotate=180"
                    ];
                };
              };

              networking = {
                hostName = "circuix";
                useNetworkd = true;
                useDHCP = false;
                wireless = {
                  enable = true;
                  interfaces = [ "wlan0" ];
                  # Put your wifi credentials here
                  # also make sure to read the security implications of this
                  # option:
                  # https://nixos.org/manual/nixos/stable/options.html#opt-networking.wireless.networks
                  networks."my ssid".psk = "my very secret password";
                  extraConfig = ''
                    country=FR
                  '';
                };
              };

              systemd.network.networks = {
                enu1u4c2 = {
                  name = "enu1u4c2";
                  DHCP = "ipv4";
                };
                wlan0 = {
                  name = "wlan0";
                  DHCP = "ipv4";
                };
              };

              security.sudo.wheelNeedsPassword = false;

              services.openssh.enable = true;

              users.users.pi = {
                isNormalUser = true;
                initialPassword = "raspberry";
                extraGroups = [
                  # To be able to use the joypad
                  "input"
                  # To be able to use the frame buffer
                  "video"
                  # Enable ‘sudo’ for the user.
                  "wheel"
                ];
                # Put your ssh pub key here
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAA..."
                ];
              };

              nix.settings.trusted-users = [ "root" "pi" ];

              environment.systemPackages = [
                pkgs.cs-hud
                pkgs.emulationstation
                pkgs.retroarch
                pkgs.util-linux
                pkgs.vim
                pkgs.wiringpi
              ];

              systemd.services.cs-hud = {
                description = "Circuit Sword HUD/OSD Service";
                wantedBy = [ "multi-user.target" ];
                path = [
                  # cs-hud uses amixer to change the volume
                  pkgs.alsa-utils
                  # it also needs to be able to find cs_shutdown.sh
                  pkgs.cs-hud
                ];
                serviceConfig.ExecStart = "${pkgs.cs-hud}/bin/cs-hud";
              };

              systemd.services.emulationstation = {
                description = "EmulationStation Service";
                wantedBy = [ "multi-user.target" ];
                path = [ pkgs.retroarch ];
                serviceConfig = {
                  User = "pi";
                  ExecStart = "${pkgs.emulationstation}/bin/emulationstation";
                };
              };
            })
        ];

      };

      devShell.x86_64-linux =
        pkgs.mkShell {
          buildInputs =
            [
              # The device tree compiler
              pkgs.dtc
              # Tools to compile cs-hud
              pkgs.gcc
              pkgs.gnumake
              pkgs.libpng
              pkgs.libraspberrypi
              pkgs.linuxHeaders
              pkgs.pkg-config
              pkgs.wiringpi
            ];
          INCLUDES = "-I${pkgs.linuxHeaders}/include";
        };
    };
}
