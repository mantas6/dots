{...}: {
  flake.modules.nixos.base = {...}: {
    nix = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["mantas"];
      };

      optimise = {
        automatic = true;
        dates = ["weekly"];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}
