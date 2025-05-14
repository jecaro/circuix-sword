arduino-nix: arduino-index:
[
  (arduino-nix.mkArduinoPackageOverlay (arduino-index + "/index/package_index.json"))
  (arduino-nix.mkArduinoLibraryOverlay (arduino-index + "/index/library_index.json"))
  (arduino-nix.overlay)
  (import ./arduino-cli.nix arduino-nix arduino-index)
]

