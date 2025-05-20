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
download a prebuilt image from the [releases] page. If dowloading an image from 
the [releases] page, make sure to follow the `README.md` of the downloaded 
version.

## Initialize the system

- Put the card in your `Circuit-Sword`. Turn it on once. The image will boot, 
  resize the root partition to fill the SD card, and perform some other 
  initialization.

- `retroarch` should be automatically started. Using the gamepad, go to 
  `Settings/Wi-Fi` and configure your wifi credentials.

- Now connect to the `Circuit-Sword` via `ssh` with the default credentials and 
  change the password. The default credentials being:
  - login: `pi`
  - password: `raspberry`

## Put some roms and play

- `retroarch` runs as the `pi` user. Put your roms where you like in 
  `/home/pi`. This can be done either with `ssh` or by mounting the `NIXOS_SD` 
  partition on your computer.

- See `retroarch` [documentation](https://docs.libretro.com/) for more 
  information on how to configure it.

## Additional notes

### Differences between Kite original `Circuit-Sword` distribution

- There is currently no HUD on `circuix-sword`. This is due to the fact that 
  SDL has been upgraded to use the video driver DRM/KMS which additionally 
  allows hardware acceleration. The legacy HUD uses a deprecated API to access 
  the framebuffer. It is unfortunately not compatible with DRM/KMS. 
- The current version uses plain `retroarch` instead of the frontend 
  `emulationstation`. It is not built on top of [RetroPie].
- HDMI out is not implemented yet.

### `cs-hud` features replacement

Below are the features of the original `cs-hud` and their equivalent in
`circuix-sword` where applicable.

Currently working:
- safe shutdown
- mode + up/down: volume
- mode + left/right: brightness
- mode + Y/X: speaker

Not working:
- mode + start/select: on screen keyboard. Disabled as it is not possible with 
  KMS.
- mode + A/B: wifi. wifi setup is now possible with plain `retroarch`

HUD:
- battery level: the battery level is displayed in `retroarch`
- wifi: the wifi status can be viewed in `retroarch` in `Settings/Wi-Fi`
- temperature: not displayed yet

Not tested:
- mode + L/R: d-pad

### Update remotely

If you are comfortable with nix you can change anything in the configuration 
and update the system remotely with:

```
$ nixos-rebuild switch --flake .#circuix --target-host pi@circuix --use-remote-sudo
```

Some packages are heavily patched and can be long to compile. A binary cache is 
available at https://jecaro.cachix.org, follow the instructions there to it.

### Flash the arduino leonardo

The distribution optionally includes a script to flash the arduino leonardo. 
The sources for the firmware are in the 
[./overlays/cs-firmware/CS_FIRMWARE](./overlays/cs-firmware/CS_FIRMWARE)
directory.

- set the booleaan `withFlashCSFirmware` to `true` in the [flake](./flake.nix)
- update the system remotly as explained in the previous section
- ssh to the pi and run: `sudo flash-cs-firmware`
- reboot

The firmware binaries are also easily available on the build machine if needed:

```
$ nix build .#cs-firmware
$ ls result
CS_FIRMWARE.ino.eep  CS_FIRMWARE.ino.hex                  CS_FIRMWARE.ino.with_bootloader.hex
CS_FIRMWARE.ino.elf  CS_FIRMWARE.ino.with_bootloader.bin
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

### Related work

- [Kite original repo][Circuit-Sword]. It is worth looking at the history of 
  the wiki which contains a lot of useful information about the hardware and 
  the build process.
- [weese/Circuit-Sword][weese]: the most up-to-date fork of the original 
  software.
- [Antho91/Circuit-Sword][Antho91]: another fork of the original software.

[Circuit-Sword]: https://github.com/kiteretro/Circuit-Sword
[weese]: https://github.com/weese/Circuit-Sword
[Antho91]: https://github.com/Antho91/Circuit-Sword
[Kite]: https://kiteretro.com/
[RetroPie]: https://retropie.org.uk/
[circuix-nixos]: ./images/circuix-nixos.jpg
[circuix-retroarch]: ./images/circuix-retroarch.jpg
[nixos]: https://nixos.org/
[releases]: https://github.com/jecaro/circuix-sword/releases
[rpi-imager]: https://www.raspberrypi.com/software/
[status-png]: https://github.com/jecaro/circuix-sword/workflows/CI/badge.svg
[status]: https://github.com/jecaro/circuix-sword/actions

