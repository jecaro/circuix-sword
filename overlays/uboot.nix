# When the DPI screen is on, something on the serial line stops uboot timeout,
# just like if one have hit a key on a keyboard. We completly remove the
# timeout. It is still possible to choose the generation to boot from plugin a
# usb keyboard.
final: prev: {
  ubootRaspberryPi3_64bit = prev.ubootRaspberryPi3_64bit.override {
    extraConfig = ''
      CONFIG_BOOTDELAY=-2
    '';
  };
}

