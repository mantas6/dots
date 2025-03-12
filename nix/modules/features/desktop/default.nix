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
    ./pass.nix
  ];

  config = lib.mkIf (lib.elem "desktop" config.features) {
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
