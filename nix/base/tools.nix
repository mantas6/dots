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
      ])
      ++ [
        pkgs-unstable.neovim
      ];
  };
}
