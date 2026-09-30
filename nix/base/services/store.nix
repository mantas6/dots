{...}: {
  flake.modules.nixos.base = {...}: {
    nix = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        extra-substituters = ["https://cache.nixos-cuda.org"];
        extra-trusted-public-keys = ["cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="];
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
