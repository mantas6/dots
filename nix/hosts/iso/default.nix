{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-iso"];
  };

  flake.modules.nixos."host-iso" = {
    pkgs,
    modulesPath,
    ...
  }: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
      ])
      ++ [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      ];

    nixpkgs.hostPlatform = "x86_64-linux";

    environment.systemPackages = [pkgs.vim];
  };
}
