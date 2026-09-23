{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.tp = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-tp"];
  };

  flake.modules.nixos."host-tp" = {...}: {
    imports = with self.modules.nixos; [
      base
      base-home
      disks-encrypted
      hardware-amd
      collections-desktop
      collections-develop
      progs-shell
      services-docker
      hardware-backlight
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    networking.stevenblack.enable = true;
    networking.networkmanager.enable = true;
    users.users.mantas.extraGroups = ["networkmanager"];

    services.logind.settings.Login.HandlePowerKey = "suspend";

    networking.hostName = "tp";

    system.stateVersion = "25.05";
  };
}
