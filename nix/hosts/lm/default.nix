{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.lm = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-lm"];
  };

  flake.modules.nixos."host-lm" = {...}: {
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

    networking.hostName = "lm";

    system.stateVersion = "26.05";
  };
}
