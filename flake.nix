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
  };

  outputs = { nixpkgs, nixos-hardware, rpifirmware, ovmerge-src, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      lib = nixpkgs.lib;

      ovmerge = pkgs.stdenv.mkDerivation {
        name = "ovmerge";
        src = ovmerge-src;

        buildInputs = with pkgs; [ perl ];

        phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

        installPhase = ''
          mkdir -p $out/bin
          cp ovmerge/ovmerge $out/bin
        '';
      };
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
              ];
              # Dont compress the image its very time consuming
              sdImage.compressImage = false;

              boot = {
                # Disable building zfs, it takes a long time
                supportedFilesystems.zfs = lib.mkForce false;
                initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
              };

              console.keyMap = "fr";
              i18n.defaultLocale = "en_US.UTF-8";

              hardware = {
                # To include the wifi firmware
                enableRedistributableFirmware = true;

                deviceTree = {
                  enable = true;
                  # That the device tree we generate the overlay applied. If we
                  # dont set the name here the kernel pick the one in the
                  # FIRMWARE partition
                  name = "broadcom/bcm2710-rpi-cm3.dtb";

                  # Only keep the one for the CM3
                  filter = lib.mkDefault "bcm2710-rpi-cm3.dtb";

                  # Adapted from here: https://github.com/NixOS/nixpkgs/issues/320557#issuecomment-2176067772
                  overlays = map
                    (name: {
                      inherit name;

                      dtsFile = pkgs.runCommand "dtoverlay-${name}" { } ''
                        cd ${rpifirmware}/arch/arm/boot/dts/overlays
                        ${ovmerge}/bin/ovmerge ${name} | sed "s/brcm,bcm2835/brcm,bcm2837/g" > $out
                      '';
                    })
                    [ "sdio-overlay.dts,poll_once=false" ];
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
                initialPassword = "retropie";
                # Enable ‘sudo’ for the user.
                extraGroups = [ "wheel" ];
                # Put your ssh pub key here
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAA..."
                ];
              };

              nix.settings.trusted-users = [ "root" "pi" ];

              environment.systemPackages = with pkgs; [
                vim
                util-linux
              ];

              system.stateVersion = "24.11";
            })
        ];

      };

      devShell.x86_64-linux =
        pkgs.mkShell {
          buildInputs = [ pkgs.dtc ];
        };
    };
}
