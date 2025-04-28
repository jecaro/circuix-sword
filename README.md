# circuix-sword

[![CI][status-png]][status]

`circuix-sword` is a [nixos] system preconfigured to run on the `Circuit-Sword` 
card developed by [Kite]. It has the same goals as [the original 
software][Circuit-Sword]: offer a good gaming handheld experience out of the 
box.

![circuix-retroarch][circuix-retroarch]
![circuix-nixos][circuix-nixos]

The `Circuit-Sword` is a circuit board that perfectly fits the original DMG 
gameboy shell. Internally, it contains:
- a Raspberry Pi `CM3`
- a `MicroII` sound card
- a Realtek `8723bs` wifi chip
- a `Arduino SA Leonardo` with a custom firmware to appear as a gamepad
- a 320x240 DPI screen
- a safe-shutdown circuit

and features:
- a USB-A port
- an HDMI output
- a USB-C port for charging the battery
- a micro SD card slot
- a mode button to change the screen brightness, the volume, etc...

# Getting started

## Create the initial SD image

An SD image for the system can be created with:

```
$ nix build .#nixosConfigurations.circuix.config.system.build.sdImage
```

Then burn it on an SD card using `dd` or [rpi-imager]. Alternatively, you can 
download a prebuilt image from the [releases] page.

## Initialize the system

- Put the card in your `Circuit-Sword`. Turn it on once. The image will boot, 
  resize the root partition to fill the SD card, and perform some other 
  initialization.

- Turn off the `Circuit-Sword` and remove the SD card.

- Insert the SD card into your computer and mount the `NIXOS_SD` partition.

- Create a new file called `/etc/wpa_supplicant.conf` with the following

```
network={
  ssid="your_wifi_ssid"
  psk="your_wifi_password"
}
```

- Unmount the partition and insert the SD card back into the `Circuit-Sword`. 
  Turn it on again.

- At this point you should have wifi working. Connect to the `Circuit-Sword` 
  via `ssh` with the default credentials and change the password. The default 
  credentials being:
  - login: `pi`
  - password: `raspberry`

## Put some roms and play

- `retroarch` comes preconfigured with the built-in gamepad. It should be 
  possible to navigate in the menus with it.

- It runs as the `pi` user. Put your roms where you like in `/home/pi`. This 
  can be done either with `ssh` or by mounting the `NIXOS_SD` partition on your 
  computer.

- See `retroarch` [documentation](https://docs.libretro.com/) for more 
  information on how to configure it.

## Additional notes

### Differences between Kite original `Circuit-Sword` distribution

- The original software can be found on [the project GitHub][Circuit-Sword]. 
  More up-to-date forks can be found here:
  - https://github.com/weese/Circuit-Sword
  - https://github.com/Antho91/Circuit-Sword
- There is currently no HUD on `circuix-sword`. This is due to the fact that 
  SDL has been upgraded to use the video driver DRM/KMS which additionally 
  allows hardware acceleration. The legacy HUD uses a deprecated API to access 
  the framebuffer. It is unfortunately not compatible with DRM/KMS. Below are 
  the original keys of `cs-hud`, :white_check_mark: is working, :x: is not, 
  :question: is not tested.
  - :white_check_mark: mode + up/down: volume
  - :white_check_mark: mode + left/right: brightness
  - :white_check_mark: mode + A/B: wifi
  - :white_check_mark: mode + Y/X: speaker
  - :question: mode + L/R: d-pad
  - :x: mode + start/select: on screen keyboard
- The current version uses plain `retroarch` instead of the frontend 
  `emulationstation`. It is not built on top of [RetroPie].
- HDMI out is not implemented yet.

### Update remotely

If you are comfortable with nix you can change anything in the configuration 
and update the system remotely with:

```
$ nixos-rebuild switch --flake .#circuix --target-host pi@circuix --use-remote-sudo
```

### Gotchas

- The wifi driver seems to not properly finalize when doing a software reboot. 
  It makes the wifi fails after a `$ sudo reboot` for example. One need to use 
  the safe shutdown or `$ sudo poweroff` then remove the power. It is the same 
  for the USB driver.
- The file `config.txt` is created with the image only. It is not updated when 
  calling `nixos-rebuild switch`. It is still possible to edit it manually by 
  connecting to the pi via `ssh` and editing the file. The file is located on a 
  partition not mounted by default.
  ```
  $ ssh pi@circuix
  [pi@circuix:~]$ sudo mkdir /boot/firmware
  [pi@circuix:~]$ sudo mount /boot/firmware
  [pi@circuix:~]$ sudo vim /boot/firmware/config.txt
  ```

# TODO

- [X] Make wifi work out of the box
- [X] Configure the screen
- [X] Make the safe shutdown work
- [X] Install `cs-hud`
- [X] Make `cs-hud` work
- [X] Use KMSDRM SDL video driver -> broke the HUD, it's been disabled
- [X] Install `retroarch`
- [X] Auto start it
- [X] Boostrap `retroarch` configuration
- [X] Fix audio loudness
- [X] Add CI
- [ ] Add documentation to update the firmware
- [X] Faster boot time
- [ ] Fix warning: `cd-hud uses wireless extensions which will stop working for 
  Wi-Fi 7 hardware; use nl80211`
- [ ] Implement a new HUD
- [ ] Find a way to toggle to HDMI out
- [ ] Use `emulationstation` instead of `retroarch`
- [ ] Find a nice theme for `emulationstation`
- [ ] Show an image during boot
- [X] Host ready to burn SD images
- [X] Find a way to use an existing image and then configure the wifi
- [X] Remove nix store path into `retroarch.cfg`

[Circuit-Sword]: https://github.com/kiteretro/Circuit-Sword
[Kite]: https://kiteretro.com/
[RetroPie]: https://retropie.org.uk/
[circuix-nixos]: ./images/circuix-nixos.jpg
[circuix-retroarch]: ./images/circuix-retroarch.jpg
[nixos]: https://nixos.org/
[releases]: https://github.com/jecaro/circuix-sword/releases
[rpi-imager]: https://www.raspberrypi.com/software/
[status-png]: https://github.com/jecaro/circuix-sword/workflows/CI/badge.svg
[status]: https://github.com/jecaro/circuix-sword/actions

