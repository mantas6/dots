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
    ./printing.nix
  ];

  options.features.list = lib.mkOption {
    type = lib.types.listOf (lib.types.enum [
      "nvidia"
      "amd"
      "desktop"
      "develop"
      "printing"

      "disks/normal"
      "disks/encrypted"
    ]);

    default = [];

    description = "List of globally enabled features for this host.";
  };
}
