{
  lib,
  config,
  ...
}: {
  imports = [
    ./xserver.nix
    ./fonts.nix
    ./audio.nix
    ./pkgs.nix
  ];

  options = {
    desktop.enable = lib.mkEnableOption "Enable desktop";
  };

  config = lib.mkIf config.desktop.enable {
    hardware.bluetooth.enable = true;

    # location.provider = "manual";
    # location.latitude = 54.0;
    # location.longitude = 25.0;
    #
    # services.redshift = {
    #   enable = true;
    #   temperature = {
    #     day = 4500;
    #     night = 4500;
    #   };
    # };

    # programs.gnupg.agent.enable = true;
  };
}
