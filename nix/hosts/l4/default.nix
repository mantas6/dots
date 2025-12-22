# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{pkgs, ...}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  disko.devices.disk.main-disk.device = "/dev/sda";

  features.sets = [
    "disks.normal"
    "jobs.updates"
    "hardware.backlight"
    "services.docker"
    "services.memos"
    # "services.photosync"
    "quirks.prevent-sleep"
  ];

  features.swapSizeInGB = 8.0;

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

      "http://nostalgia".extraConfig = ''
        reverse_proxy http://localhost:8077
      '';
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

        :8077 {
          root    * /home/mantas/Pictures/Nostalgia/Site
          file_server
        }

        :8078 {
          root    * /home/mantas/Pictures/Nostalgia/Originals
          file_server
        }

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

  systemd.user.services.sat-backups = {
    script = "/home/mantas/Offload/Sat/run";

    path = with pkgs; [
      openssl
      bash
      jq
      curl
    ];

    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
    };

    startAt = ["03:00" "09:00"];
  };

  systemd.user.timers.sat-backups = {
    timerConfig = {
      Persistent = true;
    };
  };

  services.udisks2.enable = true;

  console.font = "ter-732n";

  networking.hostName = "l4";

  system.stateVersion = "25.05";
}
