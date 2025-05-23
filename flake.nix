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

    retroarch-src = {
      url = "github:jecaro/RetroArch/circuix-sword";
      flake = false;
    };

    arduino-nix.url = "github:bouk/arduino-nix";

    arduino-index = {
      url = "github:bouk/arduino-indexes";
      flake = false;
    };
  };

  outputs =
    { nixos-hardware
    , nixos-pi-zero-2-src
    , nixpkgs
    , ovmerge-src
    , rpifirmware
    , retroarch-src
    , arduino-nix
    , arduino-index
    , ...
    }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays =
          (import ./overlays/arduino arduino-nix arduino-index) ++
          [ (import ./overlays/cs-firmware) ];
      };
      cs-firmware = pkgs.cs-firmware;
      lib = nixpkgs.lib;

    in
    {
      nixosConfigurations.circuix = lib.nixosSystem {
        system = "aarch64-linux";
        # Turn this on if you need to flash the arduino firmware
        specialArgs.withFlashCSFirmware = false;

        modules = [
          ({ config, pkgs, ... }:
            {
              imports = [
                (import ./system/sd-image.nix { inherit nixpkgs nixos-pi-zero-2-src; })
                (import ./system/hardware.nix { inherit nixos-hardware rpifirmware; })
                (import ./system/configuration.nix)
              ];

              nixpkgs = {
                overlays = [
                  # cs-firmware cannot be crossed built for some reason. we
                  # inject the version built for x86_64-linux which should be
                  # the same as the target is the arduino leonardo anyway.
                  (final: prev: { inherit cs-firmware; })
                  (import ./overlays/SDL2.nix)
                  (import ./overlays/alsa-utils.nix)
                  (import ./overlays/cs-hud)
                  (import ./overlays/flash-cs-firmware.nix)
                  (import ./overlays/mesa.nix)
                  (import ./overlays/ovmerge.nix ovmerge-src)
                  (import ./overlays/retroarch.nix retroarch-src)
                  (import ./overlays/rtl8723-firmware.nix)
                  (import ./overlays/wiringpi)
                ] ++ (import ./overlays/arduino arduino-nix arduino-index);
              };
            })
        ];
      };

      packages.x86_64-linux.cs-firmware = cs-firmware;

      devShell.x86_64-linux =
        pkgs.mkShell {
          buildInputs =
            [
              # To flash the firmware
              pkgs.arduino-cli-with-hid
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
