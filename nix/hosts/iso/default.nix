{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-iso"];
  };

  flake.modules.nixos."host-iso" = {
    config,
    lib,
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

    boot.zfs.forceImportRoot = false;

    environment.systemPackages = [pkgs.vim];

    # Allow key-only root login with the same keys as mantas.
    users.users.root.openssh.authorizedKeys.keys = config.users.users.mantas.openssh.authorizedKeys.keys;
    services.openssh.settings = {
      PermitRootLogin = lib.mkForce "prohibit-password";
      AllowUsers = ["root"];
    };
  };
}
