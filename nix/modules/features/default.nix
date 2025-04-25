{
  lib,
  ...
}: {
  imports = [
    ./desktop
    ./develop
    ./amd.nix
    ./nvidia.nix
    ./disks.nix
    ./remap.nix
  ];

  options.features = lib.mkOption {
    type = lib.types.listOf (lib.types.enum [
      "nvidia"
      "amd"
      "desktop"
      "develop"
      "disks"
      "remap"
    ]);

    default = [];

    description = "List of globally enabled features for this host.";
  };
}
