{...}: {
  flake.modules.nixos."collections-desktop" = {pkgs, ...}: {
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
