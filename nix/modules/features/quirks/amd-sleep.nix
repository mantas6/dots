{
  lib,
  config,
  ...
}: let
  name = "quirks/amd-sleep";
in {
  config = lib.mkMerge [
    {features.listAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.list) {
      # https://nixos.wiki/wiki/Power_Management
      services.udev.extraRules =
        /*
        udev
        */
        ''
          ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
        '';
    })
  ];
}
