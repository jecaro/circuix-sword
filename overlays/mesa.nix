# We get rid of the llvm dependency which is around 400MB
final: prev: {

  mesa = (prev.mesa.override {
    vulkanDrivers = [ ];
    galliumDrivers = [ "vc4" ];
    eglPlatforms = [ ];
  }).overrideAttrs (old: {
    mesonFlags = old.mesonFlags ++ [
      "-Dgallium-nine=false"
      "-Dgallium-opencl=disabled"
      "-Dgallium-rusticl=false"
      "-Dgallium-va=disabled"
      "-Dgallium-vdpau=disabled"
      "-Dgallium-xa=disabled"
      "-Dglx=disabled"
      "-Dllvm=disabled"
      "-Dmicrosoft-clc=disabled"
      "-Dopencl-spirv=false"
      "-Dosmesa=false"
      "-Dxlib-lease=disabled"
    ];

    outputs = final.lib.lists.subtractLists [ "osmesa" "spirv2dxil" ] old.outputs;
  });

}
