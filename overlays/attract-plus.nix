final: prev:
{
  attractplus = final.stdenv.mkDerivation rec {
    pname = "attractplus";
    version = "3.2.0";

    src = final.fetchFromGitHub {
      owner = "oomek";
      repo = "attractplus";
      rev = version;
      fetchSubmodules = true;
      sha256 = "sha256-vc3HnmSDisyVOSP16FKjUCPdNcSz0EaqjU57xS+4aqs=";
    };

    nativeBuildInputs = [ final.pkg-config final.cmake ];

    # Internal SFML headers (required since USE_SYSTEM_SFML=0)
    NIX_CFLAGS_COMPILE = "-I./obj/sfml/install/include";
    NIX_LDFLAGS = "-L./obj/sfml/install/lib64";

    makeFlags = [
      "prefix=${placeholder "out"}"

      # --- THE REQUESTED FLAGS ---
      "USE_DRM=1" # Direct Hardware Access
      "USE_GLES=1" # Native Pi Graphics
      "STATIC=1" # Link dependencies statically
      "USE_SYSTEM_SFML=0" # Use the patched internal SFML
    ];

    buildInputs = with final.pkgs; [
      ffmpeg
      libarchive
      libjpeg
      openal
      freetype
      zlib
      expat
      fontconfig
      curl
      libogg
      libvorbis
      flac
      sfml_2

      # --- NIXOS STATIC BOOST FIX ---
      # We must explicitly request the static (.a) versions of Boost
      # so that STATIC=1 can find them.
      (boost.override { enableStatic = true; })

      # Hardware
      udev
      libdrm
      mesa # amp needs gbm including in mesa, but mesa is trimmed down in our mesa overlay

      # Graphics
      libGLU
      libglvnd
      xorg.libX11
      xorg.libXrandr
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
    ];

    dontUseCmakeConfigure = true;
    enableParallelBuilding = true;

    # --- LINKER PATCH ---
    # The Makefile asks for "-l:libboost_filesystem.a" which is too strict for Nix.
    # We change it to "-lboost_filesystem", which lets Nix find the static file automatically.
    postPatch = ''
      echo "Patching Makefile to fix Boost linking..."
      sed -i 's/-l:libboost_filesystem.a/-lboost_filesystem/g' Makefile
      sed -i 's/-l:libboost_system.a/-lboost_system/g' Makefile

      # Fix missing header
      sed -i '1i#include <optional>' src/fe_file.cpp
      sed -i '1i#include <optional>' src/fe_file.hpp
    '';

    preInstall = ''
      mkdir -p $out/bin $out/share/attract
    '';

  };

}
