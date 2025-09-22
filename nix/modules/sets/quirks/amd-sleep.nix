{
  lib,
  config,
  ...
}: let
  name = "quirks/amd-sleep";
in {
  config = lib.mkMerge [
    {features.setsAvailable = [name];}
    (lib.mkIf (lib.elem name config.features.sets) {
      # https://nixos.wiki/wiki/Power_Management
      services.udev.extraRules =
        /*
        udev
        */
        ''
          ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
        '';

      boot.kernelParams = [
        "processor.max_cstate=1"
      ];
    })
  ];
}
