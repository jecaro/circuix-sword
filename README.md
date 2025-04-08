TODO:
- [ ] Make wifi work out of the box
- [ ] Configure the screen
- [ ] Make the safe shutdown works
- [ ] Install cs-hud
- [ ] Make cs-hud works
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

