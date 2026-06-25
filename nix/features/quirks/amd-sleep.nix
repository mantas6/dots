{...}: {
  flake.nixosModules."quirks-amd-sleep" = {
    lib,
    config,
    ...
  }: {
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
  };
}
