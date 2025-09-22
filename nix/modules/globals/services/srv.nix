{
  lib,
  config,
  pkgs,
  ...
}: {
  options.features.services = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "List of instance names for myservice@.service";
  };

  config = {
    systemd.services = builtins.listToAttrs (
      map (name: {
        name = "srv-${name}";

        value = {
          enable = true;

          # script = "sleep 60";

          after = ["network.target"];
          wantedBy = ["default.target"];

          # path = [pkgs.bash];
          environment = {
            # PATH = "/run/current-system/sw/bin";
            HOME = "/home/mantas";
          };

          serviceConfig = {
            User = "mantas";
            ExecStart = "/home/mantas/.dots/bin/dot/menv /home/mantas/.dots/srv/${name}/run";
            WorkingDirectory = "/home/mantas/.dots/srv/${name}";
            # ExecStart = ''sleep 60'';
            # Type = "simple";
            Restart = "always";
            RestartSec = "60s";
          };
        };
      })
      config.features.services
    );
  };
}
