{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "printing";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      services = {
        printing = {
          enable = true;
          drivers = with pkgs; [
            cups-filters
            cups-browsed
          ];
        };

        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
      };

      hardware.printers = {
        ensureDefaultPrinter = "Brother_HL-L2445DW";
        ensurePrinters = [
          {
            deviceUri = "ipp://BRN94DDF82B172F/ipp";
            location = "home";
            name = "Brother_HL-L2445DW";
            model = "everywhere";
          }
        ];
      };
    })
  ];
}
