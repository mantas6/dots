{...}: {
  flake.modules.nixos."host-l4" = {
    self,
    pkgs,
    ...
  }: {
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

    # Launch the dashboard on the autologin VT via the `sat` binary.
    # kmscon uses a pty, so detect the VT with XDG_VTNR rather than tty.
    environment.loginShellInit = ''
      if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
        exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.sat}/bin/sat dashboard --follow
      fi
    '';
  };
}
