# final to use the patched version of wiringPi
final: _: {
  cs-hud = final.stdenv.mkDerivation {
    name = "cs-hud";

    src = ./src;

    nativeBuildInputs = [
      final.pkgs.libpng
      final.pkgs.libraspberrypi
      final.pkgs.makeWrapper
      final.pkgs.wiringpi
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp cs-hud $out/bin/
      cp cs_shutdown.sh $out/bin/
    '';
  };

}
