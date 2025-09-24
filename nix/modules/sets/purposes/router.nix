{
  lib,
  config,
  ...
}: let
  name = "purposes.router";

  lanIfName = "net0";
  lanDeviceMac = "98:fa:9b:9e:ef:fb";

  wanIfName = "internet0";
  wanDeviceMac = "00:1b:21:f0:6c:e0";
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

          # interface="${lanIfName}";

          # listenAddress="::1,127.0.0.1,192.168.0.1";
          # dhcpRange="192.168.0.1,192.168.0.255,infinite";

          cache-size = 10000;

          local = "/lan/";
          domain = "lan";

          expand-hosts = true;
          domain-needed = true;
        };
      };

      systemd.network.links."10-${lanIfName}" = {
        matchConfig.PermanentMACAddress = lanDeviceMac;
        linkConfig = {
          Name = lanIfName;
        };
      };

      systemd.network.links."10-${wanIfName}" = {
        matchConfig.PermanentMACAddress = wanDeviceMac;
        linkConfig = {
          Name = wanIfName;
        };
      };

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      networking = {
        nat.enable = false;
        firewall.enable = false;

        nftables = {
          enable = true;

          # ruleset = ''
          #   table inet filter {
          #     # enable flow offloading for better throughput
          #     flowtable f {
          #       hook ingress priority 0;
          #       devices = { ppp0, lan };
          #     }
          #
          #     chain output {
          #       type filter hook output priority 100; policy accept;
          #     }
          #
          #     chain input {
          #       type filter hook input priority filter; policy drop;
          #
          #       # Allow trusted networks to access the router
          #       iifname {
          #         "lan",
          #       } counter accept
          #
          #       # Allow returning traffic from ppp0 and drop everthing else
          #       iifname "ppp0" ct state { established, related } counter accept
          #       iifname "ppp0" drop
          #     }
          #
          #     chain forward {
          #       type filter hook forward priority filter; policy drop;
          #
          #       # enable flow offloading for better throughput
          #       ip protocol { tcp, udp } flow offload @f
          #
          #       # Allow trusted network WAN access
          #       iifname {
          #               "lan",
          #       } oifname {
          #               "ppp0",
          #       } counter accept comment "Allow trusted LAN to WAN"
          #
          #       # Allow established WAN to return
          #       iifname {
          #               "ppp0",
          #       } oifname {
          #               "lan",
          #       } ct state established,related counter accept comment "Allow established back to LANs"
          #     }
          #   }
          #
          #   table ip nat {
          #     chain prerouting {
          #       type nat hook prerouting priority filter; policy accept;
          #     }
          #
          #     # Setup NAT masquerading on the ppp0 interface
          #     chain postrouting {
          #       type nat hook postrouting priority filter; policy accept;
          #       oifname "ppp0" masquerade
          #     }
          #   }
          # '';
        };
      };

      # networking.firewall.extraCommands = [
      #   "iptables -t nat -A POSTROUTING -o ${wanIfName} -j MASQUERADE"
      #   "iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
      #   "iptables -A FORWARD -i ${lanIfName} -o ${wanIfName} -j ACCEPT"
      #   "iptables -I INPUT -p udp --dport 67 -i ${lanIfName}  -j ACCEPT"
      #   "iptables -I INPUT -p udp --dport 53 -s 192.168.123.0/24 -j ACCEPT"
      #   "iptables -I INPUT -p tcp --dport 53 -s 192.168.123.0/24 -j ACCEPT"
      # ];
    })
  ];
}
