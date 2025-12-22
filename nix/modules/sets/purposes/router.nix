{
  self,
  pkgs,
  pkgs-unstable,
  lib,
  config,
  ...
}: let
  name = "purposes.router";

  lanIfName = "net0";
  lanDeviceMac = "98:fa:9b:9e:ef:fb";
  lanIp = "10.0.1.1";
  lanIpRangeEnd = "10.0.1.255";

  wanIfName = "internet0";
  wanDeviceMac = "00:1b:21:f0:6c:e0";

  servicesIp = "10.0.1.21"; # l4
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      networking.stevenblack = {
        enable = true;
        package = pkgs-unstable.stevenblack-blocklist;
      };

      services.dnsmasq = {
        enable = true;

        alwaysKeepRunning = true;
        resolveLocalQueries = false;

        settings = {
          server = [
            "8.8.8.8"
            "1.1.1.1"
          ];

          address = [
            "/gw/${lanIp}"
            "/${config.networking.hostName}/${lanIp}"

            "/nostalgia/${servicesIp}"
            "/gal/${servicesIp}"
            "/memos/${servicesIp}"
          ];

          interface = "${lanIfName}";

          listen-address = "::1,127.0.0.1,${lanIp}";
          dhcp-range = "${lanIp},${lanIpRangeEnd},infinite";

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
        "net.ipv4.ip_forward" = true;
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };

      services.openssh.settings = {
        ListenAddress = lanIp;
      };

      networking = {
        interfaces = {
          "${lanIfName}" = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "${lanIp}";
                prefixLength = 24;
              }
            ];
          };
        };

        nat.enable = false;
        firewall.enable = false;

        nftables = {
          enable = true;
          # enable = false;

          ruleset = ''
            table ip nat {
              chain prerouting {
                type nat hook prerouting priority filter; policy accept;
              }

              # Setup NAT masquerading on the ${wanIfName} interface
              chain postrouting {
                type nat hook postrouting priority filter; policy accept;
                oifname "${wanIfName}" masquerade
              }
            }
          '';

          # ruleset = ''
          #   table inet filter {
          #     # enable flow offloading for better throughput
          #     # flowtable f {
          #     #   hook ingress priority 0;
          #     #   devices = { ${wanIfName}, ${lanIfName} };
          #     # }
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
          #         "${lanIfName}",
          #       } counter accept
          #
          #       # Allow returning traffic from ${wanIfName} and drop everthing else
          #       iifname "${wanIfName}" ct state { established, related } counter accept
          #       iifname "${wanIfName}" drop
          #     }
          #
          #     chain forward {
          #       type filter hook forward priority filter; policy drop;
          #
          #       # enable flow offloading for better throughput
          #       # ip protocol { tcp, udp } flow offload @f
          #
          #       # Allow trusted network WAN access
          #       iifname {
          #               "${lanIfName}",
          #       } oifname {
          #               "${wanIfName}",
          #       } counter accept comment "Allow trusted LAN to WAN"
          #
          #       # Allow established WAN to return
          #       iifname {
          #               "${wanIfName}",
          #       } oifname {
          #               "${lanIfName}",
          #       } ct state established,related counter accept comment "Allow established back to LANs"
          #     }
          #   }
          #
          #   table ip nat {
          #     chain prerouting {
          #       type nat hook prerouting priority filter; policy accept;
          #     }
          #
          #     # Setup NAT masquerading on the ${wanIfName} interface
          #     chain postrouting {
          #       type nat hook postrouting priority filter; policy accept;
          #       oifname "${wanIfName}" masquerade
          #     }
          #   }
          # '';
        };
      };

      systemd.services.wolf = {
        description = "Wolf";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          ExecStart = "${self.packages.${pkgs.system}.wolf}/bin/wolf -i ${lanIp}:5001 -a ${lanIpRangeEnd}";
          Restart = "always";
          Type = "simple";
          DynamicUser = "yes";
        };
        # change prog?
        path = [pkgs.wakeonlan];
        environment = {
        };
      };
    })
  ];
}
