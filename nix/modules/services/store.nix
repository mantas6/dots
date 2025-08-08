{...}: {
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];

    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  programs.nh = {
    enable = true;
    flake = "/home/mantas/.dots";

    clean = {
      enable = true;
      extraArgs = "--keep 10 --keep-since 30d";
    };
  };
}
