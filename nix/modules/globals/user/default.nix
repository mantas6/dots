{pkgs, ...}: {
  imports = [
    ./authorized-keys.nix
  ];

  users.users.mantas = {
    isNormalUser = true;
    # mkpasswd
    hashedPassword = "$y$j9T$ZhKXn9KIagbM2wzlkOXfz/$RQmrNYqwkbYre0BgLJ83nCHAWr6e/QCABtax5gXN6k.";
    extraGroups = ["wheel" "dialout"];
  };

  environment.variables.EDITOR = "${pkgs.vim}/bin/vim";
}
