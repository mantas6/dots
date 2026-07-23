{...}: {
  # Pull-based backup of hermes state.
  #
  # `services-hermes-backup`        -> the pulling host (l4): rsnapshot pulls
  #                                    /var/lib/hermes from rt over ssh.
  # `services-hermes-backup-source` -> the source host (rt): exposes a
  #                                    dedicated, restricted key that can only
  #                                    do read-only rsync of /var/lib/hermes.
  flake.modules.nixos."services-hermes-backup" = {
    lib,
    config,
    ...
  }: let
    # rsnapshot requires TAB-separated fields; build rows as lists and let
    # lib join them so we never hand-write tab characters.
    toConf = rows: lib.concatMapStringsSep "\n" (lib.concatStringsSep "\t") rows;
  in {
    age.secrets.hermes-backup-key.file = ./../../../lib/secrets/hermes-backup-key.age;
    # agenix default owner=root, mode=0400 — correct for an ssh private key.

    services.rsnapshot = {
      enable = true;

      cronIntervals = {
        daily = "50 3 * * *";
        weekly = "0 4 * * 0";
        monthly = "0 5 1 * *";
      };

      extraConfig = toConf [
        ["snapshot_root" "/var/backup/hermes/"]
        ["retain" "daily" "7"]
        ["retain" "weekly" "4"]
        ["retain" "monthly" "6"]
        ["ssh_args" "-i ${config.age.secrets.hermes-backup-key.path} -o StrictHostKeyChecking=accept-new"]
        ["backup" "root@rt:/" "hermes/"]
      ];
    };
  };

  flake.modules.nixos."services-hermes-backup-source" = {pkgs, ...}: {
    # Restricted key used by the pulling host to read /var/lib/hermes.
    # The forced rrsync command allows nothing but read-only rsync of that dir.
    # TODO: replace <BACKUP_PUBKEY> with the public half of the dedicated
    # keypair generated during setup (see services-hermes-backup).
    users.users.root.openssh.authorizedKeys.keys = [
      ''command="${pkgs.rsync}/bin/rrsync -ro /var/lib/hermes",restrict <BACKUP_PUBKEY>''
    ];
    environment.systemPackages = [pkgs.rsync]; # rrsync execs `rsync` from PATH
  };
}
