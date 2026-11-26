{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.au = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-au"];
  };

  flake.modules.nixos."host-au" = {...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal
        jobs-os-upgrade-desktop
        services-ollama
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    networking.hostName = "au";

    system.stateVersion = "26.05";
  };
}
