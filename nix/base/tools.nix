{...}: {
  flake.modules.nixos.base = {
    config,
    pkgs,
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
        config.features.neovim.package
      ];
  };
}
