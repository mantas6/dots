{
  lib,
  config,
  ...
}: let
  name = "router";
in {
  config = lib.mkMerge [
    {features.listAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.list) {
      services.dnsmasq = {
        enable = true;

        alwaysKeepRunning = true;
        resolveLocalQueries = false;

        settings = {
          server = [
            "8.8.8.8"
            "1.1.1.1"
          ];

          # interface="net0";

          # listenAddress="::1,127.0.0.1,192.168.0.1";
          # dhcpRange="192.168.0.1,192.168.0.255,infinite";

          cacheSize = 10000;

          local = "/lan/";
          domain = "lan";

          expandHosts = true;
          domainNeeded = true;
        };
      };
    })
  ];
}
