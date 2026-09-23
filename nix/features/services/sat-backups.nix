{...}: {
  flake.modules.nixos."services-sat-backups" = {
    lib,
    config,
    pkgs,
    ...
  }: {
    systemd.services.sat-backups = {
      script = "/home/mantas/Offload/Sat/run";

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
