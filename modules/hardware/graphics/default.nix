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
        "unspecified"
      ];

      default = "unspecified";

      description = "Set gpu vendor";
    };
  };
}
