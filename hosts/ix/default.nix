# vim: set tabstop=2 shiftwidth=2 expandtab:
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
    ../../modules
  ];

  develop.enable = true;
  gpu.type = "nvidia";
  shares.client.enabled = true;

  networking.hostName = "ix"; # Define your hostname.
  networking.interfaces.eth0.wakeOnLan.enable = true;
  networking.usePredictableInterfaceNames = false;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "24.05";
}
