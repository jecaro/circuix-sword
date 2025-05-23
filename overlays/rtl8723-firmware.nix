final: prev: {

  # Pull the rtl8723 firmware out of linux-firmware
  rtl8723-firmware = final.runCommand "rtl8723-firmware" { } ''
    mkdir -p $out/lib/firmware/rtlwifi/
    cp ${final.linux-firmware}/lib/firmware/rtlwifi/rtl8723bu_nic.bin $out/lib/firmware/rtlwifi/
    cp ${final.linux-firmware}/lib/firmware/rtlwifi/rtl8723bs_nic.bin $out/lib/firmware/rtlwifi/
  '';

}

