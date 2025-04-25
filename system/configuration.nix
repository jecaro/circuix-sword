{ pkgs, ... }:
{
  # For fbneo
  nixpkgs.config.allowUnfree = true;

  console.keyMap = "fr";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Paris";

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

  users.users.pi = {
    isNormalUser = true;
    initialPassword = "raspberry";
    extraGroups = [
      "audio"
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

  security.sudo.wheelNeedsPassword = false;

  nix.settings.trusted-users = [ "pi" "root" ];

  environment.systemPackages = [
    pkgs.alsa-utils
    pkgs.cs-hud
    pkgs.retroarch
    pkgs.util-linux
    pkgs.vim
    pkgs.wiringpi
  ];

  services.openssh.enable = true;

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

  systemd.services.retroarch = {
    description = "retroarch Service";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.retroarch ];
    serviceConfig = {
      User = "pi";
      ExecStart = "${pkgs.retroarch}/bin/retroarch";
    };
  };

  system = {
    userActivationScripts.retroarch = ''
      if [ ! -d ~/.config/retroarch ]; then
        mkdir -p ~/.config
        cp -r ${../files/retroarch} ~/.config/retroarch
        chmod u+w -R ~/.config/retroarch
      fi
    '';

    stateVersion = "24.11";
  };
}
