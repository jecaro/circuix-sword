TODO:
- [X] Make wifi work out of the box
- [X] Configure the screen
- [X] Make the safe shutdown works
- [X] Install cs-hud
- [X] Make cs-hud works
- [ ] Install emulationstation
- [ ] Auto start it
- [ ] Install dpi-cloner
- [ ] Make it work
- [ ] Add CI
- [ ] Add documentation to update the firmware

Create the inital sd image:
```
$ nix build .#nixosConfigurations.circuix.config.system.build.sdImage
```

Update remotly:
```
$ nixos-rebuild switch --flake .#circuix --target-host pi@circuix --use-remote-sudo
```

Gotchas:
- The wifi driver seems to not properly deinitialize. It makes the wifi fails 
  after a software reboot (`$ sudo reboot`). One need to `$ sudo poweroff` then 
  toggle the power button or unplug then plug the power chord.
- The file `config.txt` is created with the image only. It is not updated when 
  calling `nixos-rebuild switch`. It is still possible to manually by 
  connecting to the pi via ssh and editing the file. The file is located on a 
  partition not mounted by default.
  ```
  $ ssh pi@circuix
  [pi@circuix:~]$ sudo mkdir /boot/firmware
  [pi@circuix:~]$ sudo mount /boot/firmware
  [pi@circuix:~]$ sudo vim /boot/firmware/config.txt
  [pi@circuix:~]$ sudo poweroff # then toggle the power button
  ```


