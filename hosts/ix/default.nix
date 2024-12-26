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
    ./hardware.nix
    ../../modules
  ];

  desktop.enable = true;
  develop.enable = true;
  gpu.type = "nvidia";
  shares.client.enabled = true;

  programs.nix-ld.enable = true;

  networking.hostName = "ix";

  system.stateVersion = "24.05";
}
