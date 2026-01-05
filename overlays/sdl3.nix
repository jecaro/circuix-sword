final: prev:
{
  sdl3 = (prev.sdl3.override {
    libdecorSupport = false;
    pipewireSupport = false;
    pulseaudioSupport = false;
    waylandSupport = false;
    x11Support = false; # we use KMS
  }
  ).overrideAttrs (old: {
    # Suppress the warning about not using X nor wayland
    cmakeFlags = old.cmakeFlags ++ [ "-DSDL_UNIX_CONSOLE_BUILD=ON" ];
    # The tests fail in this configuration
    doCheck = false;
  });
}

