{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.sat = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-sat"];
  };

  flake.modules.nixos."host-sat" = {...}: {
    imports = with self.modules.nixos; [
      base
      disks-normal
      jobs-os-upgrade
      purposes-app-server
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    users.users.mantas.hashedPassword = "$y$j9T$9fIB3RWe.fVkunAycN6jD.$tsgfckKykjuNpmAfvcp5PqmyJdOaJG4NTpg54ESi5p3";

    system.autoUpgrade.dates = "01:00";

    networking.hostName = "sat";

    system.stateVersion = "25.05";
  };
}
