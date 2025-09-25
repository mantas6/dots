{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (lib.elem "collections.desktop" config.features.sets) {
    environment.systemPackages = with pkgs; [
      # (chromium.override {enableWideVine = true;})
      chromium
      qutebrowser
    ];

    # nixpkgs.config.allowUnfreePredicate = pkg:
    #   builtins.elem (lib.getName pkg) [
    #     "chromium"
    #     "chromium-unwrapped"
    #     "widevine-cdm"
    #   ];

    programs.chromium = {
      enable = true;

      extensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      ];

      extraOpts = {
        "BrowserSignin" = 0;
        "SyncDisabled" = true;
        "PasswordManagerEnabled" = false;
      };
    };

    programs.firefox = {
      enable = true;
      policies = {};
      preferences = {};
    };
  };
}
