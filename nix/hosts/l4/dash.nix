{...}: {
  flake.modules.nixos."host-l4" = {
    self,
    config,
    pkgs,
    ...
  }: {
    services.getty.autologinUser = "mantas";

    age.secrets = {
      sat-base-url.owner = "mantas";
      dashboard-token = {
        file = ../../_lib/secrets/dashboard-token.age;
        owner = "mantas";
      };
    };

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

    boot.blacklistedKernelModules = ["psmouse"];

    environment.loginShellInit = ''
      if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
        SAT_URL_PATH=${config.age.secrets.sat-base-url.path} \
        SAT_TOKEN_PATH=${config.age.secrets.dashboard-token.path} \
          exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.sat}/bin/sat dashboard --follow
      fi
    '';
  };
}
