{...}: {
  flake.modules.nixos.base = {
    pkgs,
    pkgs-unstable,
    ...
  }: {
    environment.systemPackages =
      (with pkgs; [
        wget
        curl
        unzip
        htop
        file
        killall
        vim
      ])
      ++ [
        pkgs-unstable.neovim
      ];
  };
}
