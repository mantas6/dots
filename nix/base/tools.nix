{...}: {
  flake.modules.nixos.base = {
    self,
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
        self.packages.${pkgs.stdenv.hostPlatform.system}.sat
      ];
  };
}
