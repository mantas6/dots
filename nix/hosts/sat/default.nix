{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.sat = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-sat"];
  };

  flake.modules.nixos."host-sat" = {lib, ...}: {
    imports = with self.modules.nixos; [
      base
      jobs-os-upgrade
      # purposes-app-server
    ];

    # Legacy BIOS boot: this host boots in BIOS mode, EFI variables are unavailable.
    # The disk device for GRUB is provided by disko via the EF02 BIOS-boot partition.
    boot.loader.grub.efiSupport = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    users.users.mantas.hashedPassword = "$y$j9T$AwtBNo.coaNT8mW1cSeSX1$OUNE6PgDGwLNJGMCjmCybz94imqMBUwrpoI0gYy8f2.";

    networking.hostName = "sat";

    system.stateVersion = "26.05";
  };
}
