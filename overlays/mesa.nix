# We get rid of the llvm dependency which is around 400MB
final: prev: {

  mesa = (prev.mesa.override {
    eglPlatforms = [ ];
    enablePatentEncumberedCodecs = false;
    galliumDrivers = [ "vc4" ];
    vulkanDrivers = [ ];
    vulkanLayers = [ ];
    withValgrind = false;
  }).overrideAttrs (old: {
    mesonFlags = old.mesonFlags ++ [
      "-Dgallium-extra-hud=false"
      "-Dgallium-rusticl=false"
      "-Dgallium-va=disabled"
      "-Dgallium-vdpau=disabled"
      "-Dglx=disabled"
      "-Dllvm=disabled"
      "-Dlmsensors=disabled"
      "-Dmicrosoft-clc=disabled"
      "-Dteflon=false"
      "-Dtools="
      "-Dxlib-lease=disabled"
    ];

    outputs = final.lib.lists.subtractLists [ "osmesa" "spirv2dxil" ] old.outputs;
  });

}
