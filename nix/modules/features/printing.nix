{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "printing" config.features.list) {
    services = {
      printing.enable = true;

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    environment.systemPackages = with pkgs; [
      mandoc
    ];
  };
}
