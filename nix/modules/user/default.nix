{pkgs, ...}: {
  imports = [
    ./authorized-keys.nix
  ];

  users.defaultUserShell = pkgs.zsh;

  users.users.mantas = {
    isNormalUser = true;
    password = "2";
    extraGroups = ["wheel"];
  };

  environment.variables.EDITOR = "${pkgs.neovim}/bin/nvim";
  programs.zsh.enable = true;
  services.getty.autologinUser = "mantas";
}
