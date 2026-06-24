{
  lib,
  config,
  ...
}: {
  config = {
    services.keyd = {
      enable = lib.elem "collections.desktop" config.features.sets;

      keyboards.default = {
        ids = ["*"];

        settings = {
          # Caps Lock -> Left Control
          main = {
            capslock = "leftcontrol";
          };

          # Left Alt + key -> word navigation
          alt = {
            left = "C-left";
            right = "C-right";
            backspace = "C-backspace";
          };

          # Super + key -> line nav / browser / delete
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
