{...}: {
  flake.modules.nixos.base-home = {
    self,
    pkgs,
    ...
  }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.sat
    ];
  };
}
