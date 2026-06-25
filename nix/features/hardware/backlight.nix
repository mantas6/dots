{...}: {
  flake.nixosModules."hardware-backlight" = {
    lib,
    config,
    pkgs,
    ...
  }: {
    environment.systemPackages = with pkgs; [
      brightnessctl
    ];

    services.udev.extraRules =
      /*
      udev
      */
      ''
        ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
      '';

    users.users.mantas = {
      extraGroups = ["video"];
    };
  };
}
