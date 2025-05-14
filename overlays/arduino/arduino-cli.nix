arduino-nix: arduino-index: final: prev:
let
  HID-Project = arduino-nix.latestVersion prev.arduinoLibraries.HID-Project;
  avr = arduino-nix.latestVersion prev.arduinoPackages.platforms.arduino.avr;
in
{
  arduino-cli-with-hid = final.wrapArduinoCLI {
    libraries = [ HID-Project ];
    packages = [ avr ];
  };
}
