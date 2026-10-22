{...}: {
  flake.modules.nixos."purposes-router" = {
    self,
    pkgs,
    pkgs-unstable,
    config,
    lib,
    ...
  }: let
    lanIfName = "net0";
    lanDeviceMac = "98:fa:9b:9e:ef:fb";
    lanIp = "10.0.1.1";
    lanIpRangeEnd = "10.0.1.255";

    wanIfName = "internet0";
    wanDeviceMac = "00:1b:21:f0:6c:e0";

    servicesIp = "10.0.1.21"; # l4
    wolPort = 5001;

    # Invoked by dnsmasq as `<action> <mac> <ip> [hostname]` on lease changes.
    # Every event is forwarded as-is; the receiver decides what to do with it.
    dhcpLeaseReport = pkgs.writeShellApplication {
      name = "dhcp-lease-report";
      runtimeInputs = [pkgs.curl];
      text =
        /*
        bash
        */
        ''
          case "''${1:-}" in
            add | old | del) ;;
            *) exit 0 ;;
          esac

          base_url=$(<${config.age.secrets.sat-base-url.path})
          token=$(<${config.age.secrets.leases-token.path})

          # Short timeouts: dnsmasq runs lease scripts one at a time, so a slow
          # receiver would delay later lease events. Never fail the script
          # runner either; errors land in dnsmasq's journal.
          curl \
            --fail \
            --silent \
            --show-error \
            --connect-timeout 3 \
            --max-time 5 \
            --output /dev/null \
            --header 'Accept: application/json' \
            --header "Authorization: Bearer $token" \
            --data-urlencode "action=$1" \
            --data-urlencode "mac=$2" \
            --data-urlencode "ip=$3" \
            --data-urlencode "expires_at=''${DNSMASQ_LEASE_EXPIRES:-}" \
            --data-urlencode "details[hostname]=''${4:-}" \
            --data-urlencode "details[supplied_hostname]=''${DNSMASQ_SUPPLIED_HOSTNAME:-}" \
            --data-urlencode "details[vendor_class]=''${DNSMASQ_VENDOR_CLASS:-}" \
            --data-urlencode "details[client_id]=''${DNSMASQ_CLIENT_ID:-}" \
            --data-urlencode "details[interface]=''${DNSMASQ_INTERFACE:-}" \
            --data-urlencode "details[tags]=''${DNSMASQ_TAGS:-}" \
            "''${base_url%/}/api/leases" \
            || echo "dhcp-lease-report: failed to report $1 for $3 ($2)" >&2
        '';
    };
  in {
    # The lease script runs as the dnsmasq user (see dhcp-scriptuser below).
    age.secrets = {
      leases-token = {
        file = ../../_lib/secrets/leases-token.age;
        group = "dnsmasq";
        mode = "0440";
      };
      sat-base-url = {
        group = "dnsmasq";
        mode = "0440";
      };
    };

    networking.stevenblack = {
      enable = true;
      package = pkgs-unstable.stevenblack-blocklist;
    };

    # dnsmasq serves /etc/hosts to LAN clients and those entries override
    # `address=` rules, so the default `127.0.0.2 pd` line made every client
    # resolve the router to its own loopback. Map the hostname to the LAN IP
    # instead.
    networking.hosts = {
      "127.0.0.2" = lib.mkForce [];
      "${lanIp}" = [config.networking.hostName "gw"];
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
          "/pb/${servicesIp}"
        ];

        interface = "${lanIfName}";

        # listen-address = "::1,127.0.0.1,${lanIp}";
        listen-address = "127.0.0.1,${lanIp}";
        dhcp-range = "${lanIp},${lanIpRangeEnd},30d";

        cache-size = 10000;

        local = "/lan/";
        domain = "lan";

        expand-hosts = true;
        domain-needed = true;

        dhcp-script = "${dhcpLeaseReport}/bin/dhcp-lease-report";
        dhcp-scriptuser = "dnsmasq";
        # Also report renewals, so the receiver sees when a device is still around.
        script-on-renewal = true;
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
      # "net.ipv6.conf.all.forwarding" = true;
    };

    # Cumulative WAN traffic accounting for the whole home setup.
    # Query over SSH, e.g. `vnstat -i ${wanIfName}`.
    services.vnstat.enable = true;
    environment.systemPackages = [pkgs.vnstat];

    services.openssh.settings = {
      ListenAddress = lanIp;
    };

    networking = {
      interfaces = {
        "${wanIfName}" = {
          useDHCP = true;
        };

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

      nat = {
        enable = true;
        enableIPv6 = false;
        internalInterfaces = [lanIfName];
        externalInterface = wanIfName;
      };

      firewall = {
        enable = true;
        allowPing = false;

        interfaces.${wanIfName}.allowedTCPPorts = [];

        interfaces.${lanIfName} = {
          allowedTCPPorts = [22 53 wolPort];
          allowedUDPPorts = [53 67 68];
        };
      };
    };

    systemd.services.wolf = {
      description = "Wolf";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${self.packages.${pkgs.stdenv.hostPlatform.system}.wolf}/bin/wolf -i ${lanIp}:${toString wolPort} -a ${lanIpRangeEnd}";
        Restart = "always";
        Type = "simple";
        DynamicUser = "yes";
      };
      # change prog?
      path = [pkgs.wakeonlan];
      environment = {
      };
    };
  };
}
