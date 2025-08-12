ovmerge-src: final: prev: {

  ovmerge = prev.pkgs.stdenv.mkDerivation {
    name = "ovmerge";
    src = ovmerge-src;

    buildInputs = [ prev.pkgs.perl ];

    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      # nix 2.28.3 doesn't cd into the subdirectory
      if [ -d ovmerge ]; then
        cd ovmerge
      fi

      cp ovmerge $out/bin
    '';
  };

}

