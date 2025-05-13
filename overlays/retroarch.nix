retroarch-src: prev: final:
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
      configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-wifi" ];

      src = retroarch-src;
    });
}
