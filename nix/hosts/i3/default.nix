{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.i3 = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-i3"];
  };

  flake.modules.nixos."host-i3" = {...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal
        jobs-os-upgrade
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/sda";

    networking.hostName = "i3";

    system.stateVersion = "26.05";
  };
}
