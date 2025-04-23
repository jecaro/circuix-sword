# USB audio kernel modules with the volume loudness fixed for MicroII, the
# builtin audio chip of the Circuit Sword.
#
# With stock snd-usb-audio the volume ranges from -1dB to 0dB with 256 steps,
# making it way too loud all the time.

# This builds only the USB audio modules with a patch as explained here:
# https://nixos.wiki/wiki/Linux_kernel#Patching_a_single_In-tree_kernel_module
{ pkgs, kernel }:
pkgs.stdenv.mkDerivation {
  pname = "snd-usb-audio-modules";
  inherit (kernel) src version postPatch nativeBuildInputs;

  kernel_dev = kernel.dev;
  kernelVersion = kernel.modDirVersion;

  modulePath = "sound/usb";

  # Patch recreated with the rasbperry linux sources and
  # https://github.com/weese/Circuit-Sword/tree/5241ded2721c560d20aa9f9912809b9221f190de/sound-module
  patches = [ ./fix-volume.patch ];

  buildPhase = ''
    BUILT_KERNEL=$kernel_dev/lib/modules/$kernelVersion/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config        .
    cp $kernel_dev/vmlinux          .

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath modules
  '';

  installPhase = ''
    make \
      INSTALL_MOD_PATH="$out" \
      XZ="xz -T$NIX_BUILD_CORES" \
      M="$modulePath" \
      modules_install
  '';
}

