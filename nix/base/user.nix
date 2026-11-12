{...}: {
  flake.modules.nixos.base = {...}: {
    users.mutableUsers = false;

    users.users.mantas = {
      isNormalUser = true;
      linger = true;
      extraGroups = ["wheel"];
    };

    # Stable vim keeps minimal hosts off nixpkgs-unstable; interactive shells
    # switch EDITOR to nvim when it is installed (sh/zprofile.d/50-general.zsh).
    programs.vim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
