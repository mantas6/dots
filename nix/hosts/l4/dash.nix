{...}: {
  flake.modules.nixos."host-l4" = {pkgs, ...}: {
    # TTY monitor dashboard: autologin + kmscon console.
    services.getty.autologinUser = "mantas";

    console.font = "ter-732n";

    services.kmscon = {
      enable = true;
      hwRender = true;
      fonts = [
        {
          name = "AnonymicePro Nerd Font Mono";
          package = pkgs.nerd-fonts.anonymice;
        }
      ];
      extraConfig = ''
        font-engine=pango
        font-size=30
        dpms-timeout=0
      '';
    };

    # Disable the laptop trackpad/trackpoint (PS/2). kmscon otherwise
    # picks it up and draws a pointer.
    boot.blacklistedKernelModules = ["psmouse"];
  };
}
