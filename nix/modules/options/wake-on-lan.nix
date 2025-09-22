{
  lib,
  config,
  ...
}: {
  options = {
    features.wakeOnLanAdapterMAC = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "04:7c:16:4f:88:ea";
      description = "MAC address of adapter being used for WOL";
    };
  };

  config = lib.mkIf (config.features.wakeOnLanAdapterMAC != null) {
    systemd.network.links."10-net0" = {
      matchConfig.PermanentMACAddress = config.features.wakeOnLanAdapterMAC;
      linkConfig = {
        Name = "net0";
        WakeOnLan = "magic";
      };
    };
  };
}
