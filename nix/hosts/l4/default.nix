{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.l4 = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-l4"];
  };

  flake.modules.nixos."host-l4" = {...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal
        jobs-os-upgrade
        hardware-backlight
        services-auto-brightness-sun
        progs-shell
        purposes-dashboard
        services-docker
        containers-memos
        services-rustypaste
        # containers-speedtest
        services-photosync
        quirks-prevent-sleep
        services-sat-backups
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/sda";

    users.users.mantas.hashedPassword = "$y$j9T$U4eWc1xmu7cyfRRNNVhw..$253NIyRnmx6bVSI60udjEOo8INSmMZehhWg90bVWF8B";

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

    networking.hostName = "l4";

    system.stateVersion = "25.05";
  };
}
