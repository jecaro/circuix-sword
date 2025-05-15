retroarch-src: final: prev:
{
  retroarch = prev.retroarch.override {
    cores = [
      prev.libretro.fbneo
      prev.libretro.genesis-plus-gx
      prev.libretro.mgba
      prev.libretro.nestopia
      prev.libretro.puae
      prev.libretro.snes9x
    ];
  };

  retroarchBare = prev.retroarchBare.overrideAttrs
    (old: {
      configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-wifi" ];

      src = retroarch-src;
    });
}
