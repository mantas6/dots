{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ag = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-ag"];
  };

  flake.modules.nixos."host-ag" = {...}: {
    imports = with self.modules.nixos; [
      base
      base-home
      disks-normal

      jobs-os-upgrade-desktop

      # purposes-app-server

      collections-develop
      progs-shell
      services-docker
      services-claude-timer
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    features.wakeOnLanAdapterMAC = "a8:2b:dd:4e:10:2e";

    features.swapSizeInGB = 2;

    networking.hostName = "ag";

    system.stateVersion = "26.05";
  };
}
