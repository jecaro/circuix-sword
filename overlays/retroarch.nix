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

  retroarchBare = (prev.retroarchBare.override {
    withWayland = false;
  }).overrideAttrs
    (old: {
      # disable qt and non used dependencies
      buildInputs = final.lib.lists.subtractLists
        [ final.ffmpeg final.qt5.qtbase ]
        old.buildInputs;
      nativeBuildInputs = final.lib.lists.remove
        final.qt5.wrapQtAppsHook
        old.nativeBuildInputs;

      configureFlags = (old.configureFlags or [ ]) ++ [
        "--disable-pulse"
        "--disable-qt"
        "--disable-wayland"
        "--disable-x11"
        "--disable-xinerama"
        "--disable-xrandr"
        "--enable-wifi"
      ];

      src = retroarch-src;
    });
}
