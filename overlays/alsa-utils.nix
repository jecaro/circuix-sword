final: prev: {
  alsa-utils = (prev.alsa-utils.override {
    withPipewireLib = false;
  }).overrideAttrs (old: {
    # This is a copy of the postFixup step in nixpkgs without copying all the
    # plugins
    postFixup = ''
      mv $out/bin/alsa-info.sh $out/bin/alsa-info
      wrapProgram $out/bin/alsa-info --prefix PATH : "${
        final.lib.makeBinPath [
          final.which
          final.pciutils
          final.procps
        ]
      }"
    '';
  });
}
