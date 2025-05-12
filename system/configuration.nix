{ lib, pkgs, ... }:
{
  # For fbneo
  nixpkgs.config.allowUnfree = true;

  # Disable virtual consoles
  console.enable = false;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Paris";

  networking = {
    hostName = "circuix";
    firewall.enable = false;

    useDHCP = false;
    networkmanager = {
      enable = true;
      plugins = lib.mkForce [ ];
      # Without this option, when one call `nmcli radio wifi off`, reboot, then
      # call `nmcli radio wifi on`, the wifi is unable to reconnect until the
      # next reboot.
      wifi.scanRandMacAddress = false;
    };
  };

  users.users.pi = {
    isNormalUser = true;
    initialPassword = "raspberry";
    extraGroups = [
      "audio"
      # To be able to use the joypad
      "input"
      # Enable the user to change the wifi settings
      "networkmanager"
      # To be able to use the frame buffer
      "video"
      # Enable ‘sudo’ for the user.
      "wheel"
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

  services = {
    openssh.enable = true;
    # Dont keep to much logs
    journald.extraConfig = "SystemMaxUse=50M";
  };

  systemd.services = {
    cs-hud = {
      description = "Circuit Sword HUD/OSD Service";
      wantedBy = [ "multi-user.target" ];
      path = [
        # cs-hud uses amixer to change the volume
        pkgs.alsa-utils
        # it also needs to be able to find cs_shutdown.sh
        pkgs.cs-hud
        # and rfkill
        pkgs.util-linux
      ];
      serviceConfig = {
        ExecStart = "${pkgs.cs-hud}/bin/cs-hud";
        Group = "users";
        # Make the socket readable by the group users
        UMask = "0002";
      };
    };

    retroarch = {
      description = "retroarch Service";
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.gawk
        pkgs.networkmanager
        pkgs.retroarch
      ];
      serviceConfig = {
        User = "pi";
        ExecStart = pkgs.writeShellScript "start-retroarch.sh" ''
          # Bootstrap the config if it does not exist
          if [ ! -d ~/.config/retroarch ]; then
            mkdir -p ~/.config
            cp -r ${../files/retroarch} ~/.config/retroarch
            chmod u+w -R ~/.config/retroarch
          fi

          # Start retroarch
          exec ${pkgs.retroarch}/bin/retroarch
        '';
      };
      environment = { CS_HUD_SOCKET = "/tmp/cs-hud.sock"; };
    };
  };

  system.stateVersion = "24.11";
}
