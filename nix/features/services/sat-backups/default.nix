{...}: {
  flake.modules.nixos."services-sat-backups" = {
    config,
    pkgs,
    ...
  }: let
    outputPath = "/home/mantas/Offload/Sat/backups";
    monthlyPath = "/home/mantas/Offload/Sat/Monthly";
    keepForDays = 365;

    # Talks to `<base url>/api/backups/{query,retrieve,mark}` with a bearer
    # token that has the `backups` ability.
    satBackup = pkgs.writeShellApplication {
      name = "sat-backup";
      runtimeInputs = with pkgs; [curl jq openssl coreutils findutils];
      text = builtins.readFile ./sat-backup.bash;
    };
  in {
    age.secrets = {
      sat-base-url.file = ../../../_lib/secrets/sat-base-url.age;
      backups-token.file = ../../../_lib/secrets/backups-token.age;
    };

    systemd.services.sat-backups = {
      description = "Pull the latest backup from Sat";

      after = ["network-online.target"];
      wants = ["network-online.target"];

      environment = {
        HOST = config.networking.hostName;
        OUTPUT_PATH = outputPath;
        MONTHLY_PATH = monthlyPath;
        KEEP_FOR = toString keepForDays;
      };

      serviceConfig = {
        Type = "oneshot";
        User = "mantas";
        LoadCredential = [
          "sat-base-url:${config.age.secrets.sat-base-url.path}"
          "backups-token:${config.age.secrets.backups-token.path}"
        ];
        ExecStart = "${satBackup}/bin/sat-backup";
      };

      startAt = ["03:00" "09:00"];
    };

    systemd.timers.sat-backups = {
      timerConfig = {
        Persistent = true;
      };
    };
  };
}
