{
  lib,
  config,
  ...
}: {
  options.features.docker-compose = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "List of instance names for myservice@.service";
  };

  config = {
    systemd.services = builtins.listToAttrs (
      map (name: {
        name = "docker-compose@${name}";

        value = {
          enable = true;

          script = "sleep 60";

          after = ["network.target"];
          wantedBy = ["default.target"];

          serviceConfig = {
            # ExecStart = ''sleep 60'';
            Type = "simple";
            Restart = "always";
          };
        };
      })
      config.features.docker-compose
    );
  };
}
