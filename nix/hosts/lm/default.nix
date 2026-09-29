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
        hardware-nvidia
        jobs-os-upgrade-desktop
        services-ollama
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    networking.hostName = "lm";

    nix.settings = {
      extra-substituters = ["https://cache.nixos-cuda.org"];
      extra-trusted-public-keys = ["cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="];
    };

    system.stateVersion = "26.05";
  };
}
