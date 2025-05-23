# SDL2 video driver kmsdrm configuration
# https://github.com/nvmd/nixos-raspberrypi/blob/main/overlays/pkgs.nix
final: prev:
{
  SDL2 = (prev.SDL2.override {
    drmSupport = true; # enough to have the effect of '--enable-video-kmsdrm'
    pipewireSupport = false;
    pulseaudioSupport = false;
    waylandSupport = false;
    withStatic = true; # needed to compile the tests
    x11Support = false; # we use KMS
  }).overrideAttrs (old: {
    pname = old.pname + "-rpi";
    configureFlags = old.configureFlags ++ [
      # these are off by default
      # https://github.com/libsdl-org/SDL/blob/SDL2/CMakeLists.txt#L417
      "--enable-arm-simd"
      "--enable-arm-neon"
    ];
  });
}

