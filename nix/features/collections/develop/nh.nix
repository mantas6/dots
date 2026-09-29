{...}: {
  flake.modules.nixos."collections-develop" = {
    programs.nh = {
      enable = true;
      flake = "/home/mantas/.dots";
    };
  };
}
