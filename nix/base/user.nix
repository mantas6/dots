{...}: {
  flake.modules.nixos.base = {pkgs-unstable, ...}: {
    users.mutableUsers = false;

    users.users.mantas = {
      isNormalUser = true;
      linger = true;
      extraGroups = ["wheel"];
    };

    environment.variables.EDITOR = "${pkgs-unstable.neovim}/bin/nvim";
  };
}
