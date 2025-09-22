{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
    # rtkit is optional but recommended
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true; # if not already enabled
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };

    environment.systemPackages = with pkgs; [
      pavucontrol
      playerctl
      alsa-utils
    ];
  };
}
