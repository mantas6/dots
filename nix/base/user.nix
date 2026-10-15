{...}: {
  flake.modules.nixos.base = {config, ...}: {
    users.mutableUsers = false;

    users.users.mantas = {
      isNormalUser = true;
      linger = true;
      extraGroups = ["wheel"];
    };

    environment.variables.EDITOR = "${config.features.neovim.package}/bin/nvim";
  };
}
