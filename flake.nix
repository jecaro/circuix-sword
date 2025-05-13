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
  };

  outputs =
    { nixos-hardware
    , nixos-pi-zero-2-src
    , nixpkgs
    , ovmerge-src
    , rpifirmware
    , retroarch-src
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
                (import ./system/sd-image.nix { inherit nixpkgs nixos-pi-zero-2-src; })
                (import ./system/hardware.nix { inherit nixos-hardware rpifirmware; })
                (import ./system/configuration.nix)
              ];

              nixpkgs = {
                overlays = [
                  (import ./overlays/SDL2.nix)
                  (import ./overlays/cs-hud)
                  (import ./overlays/ovmerge.nix ovmerge-src)
                  (import ./overlays/retroarch.nix retroarch-src)
                  (import ./overlays/wiringpi)
                ];
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
