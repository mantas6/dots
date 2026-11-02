{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.ag = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-ag"];
  };

  flake.modules.nixos."host-ag" = {lib, ...}: {
    imports =
      (with self.modules.nixos; [
        base
        base-home
        disks-normal

        jobs-os-upgrade-desktop

        # purposes-app-server

        collections-develop
        progs-shell
        services-docker
        agents-claude-timer
        agents-codex-timer
        agents-t3code
        agents-t3code-home
      ])
      ++ [./_hardware.nix];

    disko.devices.disk.main-disk.device = "/dev/nvme0n1";

    users.users.mantas.hashedPassword = "$y$j9T$Is9kgYLgnNB0KU58g9Xnb.$FavpbfQrGhGZEpKpEBqC0OTaL9DzEzJfoBaoF9a9Fx3";

    # No ~/.dots checkout on this host (see agents-t3code-home)
    programs.nh.flake = lib.mkForce "github:mantas6/dots";

    features.wakeOnLanAdapterMAC = "a8:2b:dd:4e:10:2e";

    networking.hostName = "ag";

    system.stateVersion = "26.05";
  };
}
