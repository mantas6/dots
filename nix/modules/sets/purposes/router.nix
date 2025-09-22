{
  lib,
  config,
  ...
}: let
  name = "purposes.router";

  lanDeviceName = "net0";
  lanDeviceMac = "abc";

  wanDeviceName = "internet0";
  wanDeviceMac = "abc";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
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

          cache-size = 10000;

          local = "/lan/";
          domain = "lan";

          expand-hosts = true;
          domain-needed = true;
        };
      };

      systemd.network.links."10-${lanDeviceName}" = {
        matchConfig.PermanentMACAddress = lanDeviceMac;
        linkConfig = {
          Name = lanDeviceName;
        };
      };

      systemd.network.links."10-${wanDeviceName}" = {
        matchConfig.PermanentMACAddress = wanDeviceMac;
        linkConfig = {
          Name = wanDeviceName;
        };
      };

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      # networking.firewall.extraCommands = [
      #   "iptables -t nat -A POSTROUTING -o ${wanDeviceName} -j MASQUERADE"
      #   "iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
      #   "iptables -A FORWARD -i ${lanDeviceName} -o ${wanDeviceName} -j ACCEPT"
      #   "iptables -I INPUT -p udp --dport 67 -i ${lanDeviceName}  -j ACCEPT"
      #   "iptables -I INPUT -p udp --dport 53 -s 192.168.123.0/24 -j ACCEPT"
      #   "iptables -I INPUT -p tcp --dport 53 -s 192.168.123.0/24 -j ACCEPT"
      # ];
    })
  ];
}
