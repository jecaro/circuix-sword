ovmerge-src: final: prev: {

  ovmerge = prev.pkgs.stdenv.mkDerivation {
    name = "ovmerge";
    src = ovmerge-src;

    buildInputs = [ prev.pkgs.perl ];

    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      cp ovmerge/ovmerge $out/bin
    '';
  };

}

