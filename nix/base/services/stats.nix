{...}: {
  flake.modules.nixos.base = {
    config,
    pkgs,
    lib,
    ...
  }: let
    systems = import ../../_lib/systems.nix;
    # use `fastfetch --format json -s ...` to test modules
    statsConfig = pkgs.writeText "fastfetch-stats.jsonc" (builtins.toJSON {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      logo.padding.top = 2;
      modules = [
        "title"
        "os"
        "host"
        "bios"
        "bootmgr"
        "board"
        "chassis"
        "kernel"
        "initsystem"
        "uptime"
        "loadavg"
        "processes"
        "packages"
        "shell"
        "display"
        "brightness"
        {
          type = "cpu";
          showPeCoreCount = true;
          temp = true;
        }
        "cpucache"
        "cpuusage"
        {
          type = "gpu";
          driverSpecific = true;
          temp = true;
        }
        {
          type = "codec";
          splitGPU = true;
        }
        "memory"
        "physicalmemory"
        {
          type = "swap";
          separate = true;
        }
        "disk"
        "btrfs"
        "zpool"
        {
          type = "battery";
          temp = true;
        }
        "poweradapter"
        "player"
        "media"
        {
          type = "localip";
          showIpv6 = true;
          showMac = true;
          showSpeed = true;
          showMtu = true;
          showLoop = true;
          showFlags = true;
          showAllIps = true;
        }
        "dns"
        "wifi"
        "datetime"
        "locale"
        "vulkan"
        "opengl"
        "opencl"
        "users"
        "bluetooth"
        "bluetoothradio"
        "sound"
        "camera"
        "gamepad"
        "mouse"
        "keyboard"
        "netio"
        "diskio"
        {
          type = "physicaldisk";
          temp = true;
        }
        "tpm"
        "version"
      ];
    });

    sendMachineStats = pkgs.writeShellApplication {
      name = "send-machine-stats";
      runtimeInputs = [pkgs.fastfetch pkgs.curl];
      text =
        /*
        bash
        */
        ''
          BASE_URL=$(<"$CREDENTIALS_DIRECTORY/sat-base-url")
          stats=$(fastfetch --config ${statsConfig} --json)
          endpoint="''${BASE_URL%/}/api/machine/$MACHINE_NAME"

          printf '{"stats":%s}\n' "$stats" | curl \
            --fail \
            --silent \
            --show-error \
            --connect-timeout 10 \
            --max-time 30 \
            --header 'Content-Type: application/json' \
            --data-binary @- \
            "$endpoint"
        '';
    };
  in
    lib.mkIf (builtins.hasAttr config.networking.hostName systems) {
      age.secrets.sat-base-url.file = ../../_lib/secrets/sat-base-url.age;

      systemd.services.send-machine-stats = {
        description = "Send machine statistics";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        environment = {
          MACHINE_NAME = config.networking.hostName;
        };
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          LoadCredential = "sat-base-url:${config.age.secrets.sat-base-url.path}";
          ExecStart = "${sendMachineStats}/bin/send-machine-stats";
        };
      };

      systemd.timers.send-machine-stats = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "10s";
          OnUnitActiveSec = "1min";
          RandomizedDelaySec = "10s";
        };
      };
    };
}
