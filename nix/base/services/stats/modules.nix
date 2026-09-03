{...}: {
  flake.modules.nixos.base = {lib, ...}: {
    options.features.send-machine-stats.settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      internal = true;
      default = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        # Use `fastfetch --format json -s ...` to test modules.
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
          {
            type = "command";
            key = "Last Shutdown";
            # Clean shutdowns log a shutdown/reboot target in the previous boot.
            text =
              /*
              bash
              */
              ''
                log=$(journalctl -b -1 -q 2>/dev/null)
                if [ $? -ne 0 ]; then
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
