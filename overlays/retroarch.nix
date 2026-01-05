retroarch-src: final: prev:
{
  retroarch = prev.retroarch.withCores (cores: [
    prev.libretro.fbneo
    prev.libretro.genesis-plus-gx
    prev.libretro.mgba
    prev.libretro.nestopia
    prev.libretro.puae
    prev.libretro.snes9x
  ]);

  retroarch-bare = (prev.retroarch-bare.override {
    withWayland = false;
  }).overrideAttrs
    (old: {
      # The disable switch doesn't seem to be enough to get rid of these deps
      buildInputs = final.lib.lists.subtractLists [
        # also qt
        final.ffmpeg_7
        # for pipewire
        final.pipewire
        # for qt
        final.qt6.qtbase
        # for gtk
        final.wrapGAppsHook3
      ]
        old.buildInputs;
      nativeBuildInputs = final.lib.lists.remove
        final.qt6.wrapQtAppsHook
        old.nativeBuildInputs;

      configureFlags = (old.configureFlags or [ ]) ++ [
        "--disable-pipewire"
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
