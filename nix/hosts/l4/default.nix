{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.l4 = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules."host-l4"];
  };

  flake.nixosModules."host-l4" = {...}: {
    imports = with self.nixosModules; [
      base
      disks-normal
      jobs-updates
      hardware-backlight
      progs-shell
      services-docker
      services-memos
      services-speedtest
      services-photosync
      quirks-prevent-sleep
      services-sat-backups
    ];

    disko.devices.disk.main-disk.device = "/dev/sda";

    features.swapSizeInGB = 8;
    powerManagement.powertop.enable = true;

    services.caddy = {
      enable = true;
      virtualHosts = {
        "http://memos".extraConfig = ''
          reverse_proxy http://localhost:5230
        '';
      };
    };

    services.getty.autologinUser = "mantas";

    console.font = "ter-732n";

    networking.hostName = "l4";

    system.stateVersion = "25.05";
  };
}
