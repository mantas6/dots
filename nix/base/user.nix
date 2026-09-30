{...}: {
  flake.modules.nixos.base = {
    lib,
    config,
    pkgs-unstable,
    ...
  }: {
    options = {
      features.serviceUser = lib.mkOption {
        type = lib.types.str;
        default = "mantas";
        description = "Unprivileged user that runs the per-user agent and job services";
      };
    };

    config = {
      assertions = [
        {
          assertion = config.users.users ? ${config.features.serviceUser};
          message = "features.serviceUser \"${config.features.serviceUser}\" is not a defined user";
        }
      ];

      users.mutableUsers = false;

      users.users.mantas = {
        isNormalUser = true;
        linger = true;
        extraGroups = ["wheel"];
      };

      environment.variables.EDITOR = "${pkgs-unstable.neovim}/bin/nvim";
    };
  };
}
