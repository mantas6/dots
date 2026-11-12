{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.rt = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-rt"];
  };

  flake.modules.nixos."host-rt" = {...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal
        jobs-os-upgrade
        services-hermes
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/sda";

    users.users.mantas.hashedPassword = "$y$j9T$CBUDkbjWCNFT9elDItjDs/$C6QtugeloE8JGPFJYJKeMAkhfxDFuiUYaRH4d2CMARB";

    networking.hostName = "rt";

    system.stateVersion = "26.05";
  };
}
