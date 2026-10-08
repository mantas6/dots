{...}: {
  flake.modules.nixos."purposes-router" = {
    self,
    pkgs,
    pkgs-unstable,
    config,
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
    dhcpLeaseNotify = pkgs.writeShellApplication {
      name = "dhcp-lease-notify";
      runtimeInputs = [pkgs.curl];
      text =
        /*
        bash
        */
        ''
          # "old" is replayed for known leases on start/SIGHUP and "del" is an
          # expiry, so only "add" means a newly handed out lease.
          [[ $1 == add ]] || exit 0

          mac=$2
          ip=$3
          host=''${4:-''${DNSMASQ_SUPPLIED_HOSTNAME:-unknown}}
          message="New DHCP lease: $host $ip ($mac)"
          [[ -n ''${DNSMASQ_VENDOR_CLASS:-} ]] && message+=" [$DNSMASQ_VENDOR_CLASS]"

          notify() {
            local base_url token
            base_url=$(<"${config.age.secrets.sat-base-url.path}") || return
            token=$(<"${config.age.secrets.router-token.path}") || return

            curl \
              --fail \
              --silent \
              --show-error \
              --connect-timeout 10 \
              --max-time 30 \
              --output /dev/null \
              --header 'Accept: application/json' \
              --header "Authorization: Bearer $token" \
              --data-urlencode "message=$message" \
              "''${base_url%/}/api/notify"
          }

          # Never fail dnsmasq's script runner; errors land in its journal.
          notify || echo "dhcp-lease-notify: failed to notify sat about $ip ($mac)" >&2
        '';
    };
  in {
    # The lease script runs as the dnsmasq user (see dhcp-scriptuser below).
    age.secrets = {
      router-token = {
        file = ../../_lib/secrets/router-token.age;
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

        # listen-address = "::1,127.0.0.1,${lanIp}";
        listen-address = "127.0.0.1,${lanIp}";
        dhcp-range = "${lanIp},${lanIpRangeEnd},30d";

        cache-size = 10000;

        local = "/lan/";
        domain = "lan";

        expand-hosts = true;
        domain-needed = true;

        dhcp-script = "${dhcpLeaseNotify}/bin/dhcp-lease-notify";
        dhcp-scriptuser = "dnsmasq";
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
