{...}: {
  flake.modules.nixos.base = {
    self,
    pkgs,
    ...
  }: {
    environment.systemPackages =
      (with pkgs; [
        vim
        wget
        curl
        unzip
        htop
        file
        killall
      ])
      ++ [
        self.packages.${pkgs.stdenv.hostPlatform.system}.sat
      ];
  };
}
