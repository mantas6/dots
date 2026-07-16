{...}: {
  flake.modules.nixos.base = {
    pkgs,
    ...
  }: {
    users.mutableUsers = false;

    users.users.mantas = {
      isNormalUser = true;
      linger = true;
      extraGroups = ["wheel" "dialout"];
    };

    environment.variables.EDITOR = "${pkgs.vim}/bin/vim";
  };
}
