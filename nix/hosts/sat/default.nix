{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.sat = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-sat"];
  };

  flake.modules.nixos."host-sat" = {
    config,
    pkgs,
    ...
  }: {
    imports = with self.modules.nixos; [
      base
      disks-normal
      jobs-os-upgrade
      # purposes-app-server
    ];

    disko.devices.disk.main-disk.device = "/dev/sda";

    # users.users.mantas.hashedPassword = "$y$j9T$9fIB3RWe.fVkunAycN6jD.$tsgfckKykjuNpmAfvcp5PqmyJdOaJG4NTpg54ESi5p3";

    networking.hostName = "sat";

    # Use the nftables firewall backend (needed for the named-set allowlist).
    networking.nftables.enable = true;

    # Encrypted list of source IPs/CIDRs allowed to reach SSH (one per line).
    age.secrets.sat-ssh-allowlist.file = ../../_lib/secrets/sat-ssh-allowlist.age;

    # Dedicated table holding the SSH allowlist set. Chain starts with policy
    # accept and no drop rule, so if the populate service never runs, SSH stays
    # open (fail-open, avoids remote lockout).
    networking.nftables.tables.ssh-filter = {
      family = "inet";
      content = ''
        set ssh_allow {
          type ipv4_addr
          flags interval
        }

        chain input {
          type filter hook input priority filter - 5; policy accept;
        }
      '';
    };

    # Populate the set and install the drop rule at runtime from the secret.
    systemd.services.ssh-allowlist = {
      description = "Load SSH source-IP allowlist into nftables";
      wantedBy = ["multi-user.target"];
      after = ["nftables.service"];
      requires = ["nftables.service"];
      path = [pkgs.nftables pkgs.coreutils pkgs.gnugrep pkgs.gnused];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        secret=${config.age.secrets.sat-ssh-allowlist.path}
        # strip comments/blank lines, join into a comma-separated list
        ips=$(grep -vE '^\s*(#|$)' "$secret" | paste -sd, -)

        # Refresh set contents.
        nft flush set inet ssh-filter ssh_allow
        [ -n "$ips" ] && nft add element inet ssh-filter ssh_allow { $ips }

        # Only enforce the drop when we actually have allowed IPs.
        nft flush chain inet ssh-filter input
        if [ -n "$ips" ]; then
          nft add rule inet ssh-filter input tcp dport 22 ip saddr != @ssh_allow drop
        fi
      '';
    };

    system.stateVersion = "26.05";
  };
}
