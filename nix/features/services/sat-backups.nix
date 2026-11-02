{...}: {
  flake.modules.nixos."services-sat-backups" = {
    config,
    pkgs,
    ...
  }: {
    age.secrets.backups-token.file = ../../_lib/secrets/backups-token.age;

    systemd.services.sat-backups = {
      # The backup task authenticates with a bearer token read from
      # SAT_TOKEN. Hand it over through systemd credentials so the secret
      # stays out of the unit definition and the Nix store.
      script = ''
        SAT_TOKEN=$(<"$CREDENTIALS_DIRECTORY/backups-token") \
          exec /home/mantas/Offload/Sat/run
      '';

      path = with pkgs; [
        openssl
        bash
        jq
        curl
      ];

      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        User = "mantas";
        LoadCredential = [
          "backups-token:${config.age.secrets.backups-token.path}"
        ];
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
