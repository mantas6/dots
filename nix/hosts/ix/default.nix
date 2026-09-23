{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ix = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-ix"];
  };

  flake.modules.nixos."host-ix" = {...}: {
    imports = with self.modules.nixos; [
      base
      base-home
      disks-normal
      hardware-amd
      collections-desktop
      collections-develop
      progs-shell
      progs-gaming
      # services-printing
      services-docker
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    # Hibernation
    # https://nixos.wiki/wiki/Hibernation
    boot.kernelParams = ["resume_offset=457809920"];
    boot.resumeDevice = "/dev/disk/by-uuid/c0c994a8-1809-4a81-8440-743be7370aeb";
    features.swapSizeInGB = 36;
    services.logind.settings.Login.HandlePowerKey = "hibernate";

    features.wakeOnLanAdapterMAC = "04:7c:16:4f:88:ea";

    # services.xserver.dpi = 100;

    networking.hostName = "ix";

    system.stateVersion = "25.05";
  };
}
