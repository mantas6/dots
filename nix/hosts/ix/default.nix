{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ix = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules."host-ix"];
  };

  flake.nixosModules."host-ix" = {...}: {
    imports = with self.nixosModules; [
      base
      hardware-amd
      # collections-desktop
      collections-develop
      progs-shell
      # services-printing
      services-docker
      quirks-amd-sleep
      # progs-gaming
      # disks-normal
    ];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    # Hibernation
    # boot.kernelParams = ["resume_offset=149282816"];
    # boot.resumeDevice = "/dev/disk/by-uuid/50c2c21f-5bf5-45a0-978b-941d00d2079e";
    # features.swapSizeInGB = 36;
    # services.logind.settings.Login.HandlePowerKey = "hibernate";
    # powerManagement.enable = true;

    # services.ollama = {
    #   enable = true;
    #   package = pkgs-unstable.ollama-cpu;
    # };

    # try pkgs.linuxPackages_6_10 to prevent sleep issues
    # boot.kernelPackages = pkgs.linuxPackages_6_10;
    # https://www.reddit.com/r/Fedora/comments/1gj29ub/is_anyone_having_this_suspendwake_up_problem_as/
    # https://www.reddit.com/r/Fedora/comments/1g7ke8e/workaround_sleep_issues_with_kernel_611/

    features.wakeOnLanAdapterMAC = "10:ff:e0:6d:48:60";

    # services.xserver.dpi = 100;

    networking.hostName = "ix";

    system.stateVersion = "24.05";
  };
}
