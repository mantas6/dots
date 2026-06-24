{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules."host-iso"];
  };

  flake.nixosModules."host-iso" = {
    pkgs,
    modulesPath,
    ...
  }: {
    imports =
      (with self.nixosModules; [
        base
      ])
      ++ [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      ];

    nixpkgs.hostPlatform = "x86_64-linux";

    environment.systemPackages = [pkgs.vim];
  };
}
