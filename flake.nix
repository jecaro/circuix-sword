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

              nixpkgs.overlays = [
                (import ./overlays/cs-hud)
                (import ./overlays/ovmerge.nix ovmerge-src)
                (import ./overlays/wiringpi)
              ];

              # Dont compress the image its very time consuming
              sdImage = {
                compressImage = false;
                extraFirmwareConfig = {
                  # Enable DPI
                  overscan_left = 0;
                  overscan_right = 0;
                  overscan_top = 0;
                  overscan_bottom = 0;
                  enable_dpi_lcd = 1;
                  display_default_lcd = 1;
                  dpi_group = 2;
                  dpi_mode = 87;

                  # Enable 320x240 custom display mode
                  framebuffer_width = 320;
                  framebuffer_height = 240;
                  display_rotate = 2;
                  dpi_output_format = 24597;
                  hdmi_timings = "320 1 20 30 38 240 1 4 3 10 0 0 0 60 0 9600000 1";
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
                      # For the DPI display
                      "dpi18-overlay.dts"
                      # For safe shutdown
                      "gpio-poweroff-overlay.dts,gpiopin=39,active_low=\"y\""
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
                # Enable ‘sudo’ for the user.
                extraGroups = [ "wheel" ];
                # Put your ssh pub key here
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAA..."
                ];
              };

              nix.settings.trusted-users = [ "root" "pi" ];

              environment.systemPackages = [
                pkgs.cs-hud
                pkgs.util-linux
                pkgs.vim
                pkgs.wiringpi
              ];

              systemd.services."cs-hud" = {
                description = "Circuit Sword HUD/OSD Service";
                wantedBy = [ "multi-user.target" ];
                serviceConfig.ExecStart = "${pkgs.cs-hud}/bin/cs-hud";
              };

              system.stateVersion = "24.11";
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
