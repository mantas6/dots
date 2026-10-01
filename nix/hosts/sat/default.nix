{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.sat = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.modules.nixos."host-sat"];
  };

  flake.modules.nixos."host-sat" = {lib, ...}: {
    imports =
      (with self.modules.nixos; [
        base
        disks-mbr
        jobs-os-upgrade
        purposes-app-server
      ])
      ++ [./_hardware.nix];

    boot.loader.grub.efiSupport = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    users.users.mantas.hashedPassword = "$y$j9T$tWZJEW0K.eEV.zQfnBbyh0$ieDjH/01NA6DLLeapQa1VPTnYKtP5rE36mTRi8ueuI5";

    networking.hostName = "sat";

    networking.useDHCP = lib.mkForce false;
    networking.useNetworkd = true;
    services.resolved.enable = true;

    # Public host, nothing legitimately tunnels through it
    services.openssh.settings = {
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      AllowStreamLocalForwarding = false;
    };

    age.secrets.sat-network = {
      file = ../../_lib/secrets/sat-network.age;
      path = "/etc/systemd/network/10-eth0.network";
      mode = "0444";
      symlink = false;
    };

    system.stateVersion = "26.05";
  };
}
