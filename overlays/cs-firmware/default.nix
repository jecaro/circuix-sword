final: prev: {

  cs-firmware = final.stdenv.mkDerivation {
    name = "cs-firmware";
    src = ./CS_FIRMWARE;

    buildPhase = ''
      ${final.pkgs.arduino-cli-with-hid}/bin/arduino-cli compile --fqbn arduino:avr:leonardo --output-dir ./build ./
    '';

    installPhase = ''
      mkdir -p $out
      cp build/* $out/
    '';
  };

}

