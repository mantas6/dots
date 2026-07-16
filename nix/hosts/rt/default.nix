{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.rt = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules."host-rt"];
  };

  flake.nixosModules."host-rt" = {...}: {
    imports = with self.nixosModules; [
      base
      base-home
      disks-normal
      jobs-updates
      services-hermes
    ];

    disko.devices.disk.main-disk.device = "/dev/sda";

    # boot.kernelParams = [
    #   "console=ttyS0,115200n8"
    #   "console=ttyS1,115200n8"
    #   "console=ttyS2,115200n8"
    #   "console=ttyS3,115200n8"
    # ];
    # boot.loader.grub.extraConfig = "
    #  serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    #  terminal_input serial
    #  terminal_output serial
    #   ";

    networking.hostName = "rt";

    system.stateVersion = "25.05";
  };
}
