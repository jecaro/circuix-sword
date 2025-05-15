final: prev: {

  cs-firmware = final.stdenv.mkDerivation {
    name = "cs-firmware";
    src = ./CS_FIRMWARE;

    nativeBuildInputs = [
      final.pkgs.arduino-cli-with-hid
    ];

    buildPhase = ''
      arduino-cli compile --fqbn arduino:avr:leonardo --output-dir ./build ./
    '';

    installPhase = ''
      mkdir -p $out
      cp -r build/CS_FIRMWARE.ino.with_bootloader.hex $out/
    '';
  };

}

