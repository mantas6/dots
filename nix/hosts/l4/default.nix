{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.l4 = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-l4"];
  };

  flake.modules.nixos."host-l4" = {pkgs, ...}: {
    imports = with self.modules.nixos; [
      base
      base-home
      disks-normal
      jobs-os-upgrade
      hardware-backlight
      services-auto-brightness-sun
      progs-shell
      services-docker
      containers-memos
      # containers-speedtest
      quirks-prevent-sleep
      services-sat-backups
    ];

    disko.devices.disk.main-disk.device = "/dev/sda";

    features.swapSizeInGB = 8;
    powerManagement.powertop.enable = true;

    environment.systemPackages = with pkgs; [
      exiftool
    ];

    services.caddy = {
      enable = true;
      # user = "mantas";
      virtualHosts = {
        "http://gal".extraConfig = ''
          reverse_proxy http://localhost:8079
        '';

        "http://memos".extraConfig = ''
          reverse_proxy http://localhost:5230
        '';

        # "http://nostalgia".extraConfig = ''
        #   reverse_proxy http://localhost:8077
        # '';
      };
    };

    systemd.services.gallery = {
      description = "Gallery";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      path = [pkgs.caddy];
      script = ''
        caddy run --config - --adapter caddyfile <<'EOF'
          {
            admin off
          }

          # :8077 {
          #   root    * /home/mantas/Pictures/Nostalgia/Site
          #   file_server
          # }
          #
          # :8078 {
          #   root    * /home/mantas/Pictures/Nostalgia/Originals
          #   file_server
          # }

          :8079 {
            root    * /home/mantas/Pictures/Gallery/Site
            file_server
          }

          :8080 {
            root    * /home/mantas/Pictures/Gallery/Originals
            file_server
          }
        EOF
      '';
      serviceConfig = {
        User = "mantas";
        Restart = "always";
        Type = "simple";
      };
      environment = {
      };
    };

    services.udisks2.enable = true;
    services.getty.autologinUser = "mantas";

    console.font = "ter-732n";

    services.kmscon = {
      enable = true;
      hwRender = true;
      fonts = [
        {
          name = "AnonymicePro Nerd Font Mono";
          package = pkgs.nerd-fonts.anonymice;
        }
      ];
      extraConfig = ''
        font-engine=pango
        font-size=30
        dpms-timeout=0
      '';
    };

    networking.hostName = "l4";

    system.stateVersion = "25.05";
  };
}
