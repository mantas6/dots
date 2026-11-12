{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ge = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-ge"];
  };

  flake.modules.nixos."host-ge" = {...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal

        jobs-os-upgrade
        # jobs-dots-sync

        # collections-develop
        # progs-shell
        # services-docker
        # agents-claude-timer
        # agents-codex-timer
        # agents-t3code
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    users.users.mantas.hashedPassword = "$y$j9T$CSmp9675OdFjo2lF1lya91$yToFdMvtlvjGz.aLfJ4AdIfomfk/duLlMUIajKawAp9";

    features.wakeOnLanAdapterMAC = "04:7b:cb:4a:32:ec";

    networking.hostName = "ge";

    system.stateVersion = "26.05";
  };
}
