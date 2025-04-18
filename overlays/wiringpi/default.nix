# on nixos wiringPi is not able to detect the pi version it is running on
# the patch force it to detect a cm3
_: prev:
let
  wiringPi =
    prev.wiringpi.passthru.wiringPi.overrideAttrs {
      patches = [ ./force-cm3.patch ];
      patchFlags = [ "-p2" ];
    };
  gpio =
    prev.wiringpi.passthru.gpio.overrideAttrs ({
      buildInputs = [
        prev.pkgs.libxcrypt
        prev.wiringpi.passthru.devLib
        wiringPi
      ];
    });
in
{
  wiringpi = prev.symlinkJoin {
    name = "wiringpi";
    # The original wiringpi contains two other packages but they are not needed
    # for this project
    paths = [ gpio wiringPi ];
  };
}
