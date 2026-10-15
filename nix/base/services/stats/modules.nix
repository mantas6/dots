{...}: {
  flake.modules.nixos.base = {lib, ...}: {
    options.features.send-machine-stats.settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      internal = true;
      default = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        # Use `fastfetch --format json -s ...` to test modules.
        modules = [
          "os"
          "host"
          "bios"
          "bootmgr"
          "board"
          "chassis"
          "kernel"
          "uptime"
          "loadavg"
          "processes"
          "display"
          {
            type = "cpu";
            showPeCoreCount = true;
            temp = true;
          }
          "cpuusage"
          {
            type = "gpu";
            driverSpecific = true;
            temp = true;
          }
          "memory"
          {
            type = "swap";
            separate = true;
          }
          "disk"
          {
            type = "battery";
            temp = true;
          }
          "poweradapter"
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
          "users"
          "bluetooth"
          "netio"
          "diskio"
          {
            type = "physicaldisk";
            temp = true;
          }
          {
            type = "command";
            key = "Last Shutdown";
            # Clean shutdowns log a shutdown/reboot target in the previous boot.
            text =
              /*
              bash
              */
              ''
                if ! log=$(journalctl -b -1 -q 2>/dev/null); then
                  echo ShutdownUnknown
                elif printf '%s' "$log" | grep -qE 'Reached target.*(Shutdown|Reboot|Power-Off)|systemd-shutdown'; then
                  echo ShutdownClean
                else
                  echo ShutdownDirty
                fi
              '';
          }
        ];
      };
    };
  };
}
