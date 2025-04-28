prev: final:
{
  retroarch = final.retroarch.override {
    cores = [
      final.libretro.fbneo
      final.libretro.genesis-plus-gx
      final.libretro.mgba
      final.libretro.nestopia
      final.libretro.puae
      final.libretro.snes9x
    ];
  };

  retroarchBare = final.retroarchBare.overrideAttrs
    (old: {
      patches = (old.patches or [ ]) ++ [ ./fix-nmcli-wifi-driver.patch ];

      configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-wifi" ];
    });
}
