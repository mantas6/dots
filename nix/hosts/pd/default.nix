{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.pd = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-pd"];
  };

  flake.modules.nixos."host-pd" = {...}: {
    imports = with self.modules.nixos; [
      base
      disks-normal
      jobs-updates
      purposes-router
      services-sat-backups
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    users.users.mantas.hashedPassword = "$y$j9T$9fIB3RWe.fVkunAycN6jD.$tsgfckKykjuNpmAfvcp5PqmyJdOaJG4NTpg54ESi5p3";

    features.swapSizeInGB = 2;
    # powerManagement.powertop.enable = true;

    system.autoUpgrade.dates = "01:00";

    networking.hostName = "pd";

    system.stateVersion = "25.05";
  };
}
