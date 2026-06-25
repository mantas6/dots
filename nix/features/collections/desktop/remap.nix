{...}: {
  flake.nixosModules."collections-desktop" = {
    services.keyd = {
      enable = true;

      keyboards.default = {
        ids = ["*"];

        settings = {
          main = {
            capslock = "leftcontrol";
          };

          alt = {
            left = "C-left";
            right = "C-right";
            backspace = "C-backspace";
          };

          meta = {
            left = "home";
            right = "end";
            leftbrace = "back";
            rightbrace = "forward";
            backspace = "C-S-backspace";
          };
        };
      };
    };
  };
}
