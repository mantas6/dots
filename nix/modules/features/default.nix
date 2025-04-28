{
  lib,
  ...
}: {
  imports = [
    ./desktop
    ./develop
    ./disks
    ./amd.nix
    ./nvidia.nix
  ];

  options.features = lib.mkOption {
    type = lib.types.listOf (lib.types.enum [
      "nvidia"
      "amd"
      "desktop"
      "develop"

      "disks/normal"
      "disks/encrypted"
    ]);

    default = [];

    description = "List of globally enabled features for this host.";
  };
}
