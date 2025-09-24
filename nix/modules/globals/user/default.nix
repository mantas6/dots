{pkgs, ...}: {
  imports = [
    ./authorized-keys.nix
  ];

  users.users.mantas = {
    isNormalUser = true;
    password = "2";
    extraGroups = ["wheel" "dialout"];
  };

  environment.variables.EDITOR = "${pkgs.neovim}/bin/nvim";
  services.getty.autologinUser = "mantas";
}
