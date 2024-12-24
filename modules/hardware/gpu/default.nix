{lib, ...}: {
  imports = [
    ./nvidia.nix
    ./amd.nix
    ./intel.nix
  ];

  options = {
    gpu.type = lib.mkOption {
      type = lib.types.enum [
        "nvidia"
        "amd"
        "intel"
      ];
      description = "Set gpu vendor";
    };
  };
}
