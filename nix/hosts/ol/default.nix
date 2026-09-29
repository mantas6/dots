{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ol = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-ol"];
  };

  flake.modules.nixos."host-ol" = {...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal
        hardware-nvidia
        services-ollama
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    features.wakeOnLanAdapterMAC = "04:7c:16:4f:88:ea";

    networking.hostName = "ol";

    system.stateVersion = "26.05";
  };
}
