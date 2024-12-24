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

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 1;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ix"; # Define your hostname.
  networking.interfaces.eth0.wakeOnLan.enable = true;
  networking.usePredictableInterfaceNames = false;

  # Set your time zone.
  time.timeZone = "Europe/Vilnius";

  services.logind.powerKey = "suspend";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    packages = with pkgs; [terminus_font];
    font = "ter-v32n";
    keyMap = "us";
  };

  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mantas = {
    isNormalUser = true;
    password = "2";
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtMJ6SP+1ppYvlbRSDyjhmWvDFOvKGFMD7V88h7Q6Ni mantas@amd"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwmj+D1NO4kg3E6JH4ck0q+C65hTiTh69POfqXMROhF mantas@X13"
    ];
  };

  environment.variables.EDITOR = "${pkgs.neovim}/bin/nvim";

  programs.zsh.enable = true;

  services.getty.autologinUser = "mantas";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "24.05";
}
