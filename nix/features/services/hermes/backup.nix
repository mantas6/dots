{...}: {
  flake.modules.nixos."services-hermes" = {pkgs, ...}: let
    hermesBackup = pkgs.writeShellApplication {
      name = "hermes-backup";

      runtimeInputs = with pkgs; [
        rsync
        gnutar
        gzip
        coreutils
        findutils
      ];

      text =
        /*
        bash
        */
        ''
          src="/var/lib/hermes"
          dest="/root/hermes-backup"
          mirror="$dest/.mirror"
          stamp="$(date +%Y%m%d-%H%M%S)"

          mkdir -p "$mirror"

          # Fast incremental sync of the source into a local mirror
          rsync -a --delete "$src/" "$mirror/"

          # Create a compressed snapshot archive from the mirror
          tar -czf "$dest/hermes-$stamp.tar.gz" -C "$mirror" .

          # Keep only the two most recent backups
          find "$dest" -maxdepth 1 -name 'hermes-*.tar.gz' -printf '%T@ %p\n' \
            | sort -rn | tail -n +3 | cut -d' ' -f2- | xargs -r rm -f
        '';
    };
  in {
    systemd.services.hermes-backup = {
      description = "Weekly compressed backup of /var/lib/hermes";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${hermesBackup}/bin/hermes-backup";
      };

      startAt = "weekly";
    };

    systemd.timers.hermes-backup = {
      timerConfig = {
        Persistent = true;
      };
    };
  };
}
