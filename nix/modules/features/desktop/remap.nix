{
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.xremap-flake.nixosModules.default
  ];

  config = {
    services = {
      xremap = {
        enable = lib.elem "desktop" config.features;

        withX11 = true;
        watch = true;

        yamlConfig = ''
          modmap:
            - name: Caps swap
              remap:
                capslock: C_L
          keymap:
            - name: MacOS sync
              remap:
                M-left: C_R-left
                M-right: C_R-right
                SUPER-left: home
                SUPER-right: end
                SUPER-leftbrace: back
                SUPER-rightbrace: forward
                SUPER-backspace: C_R-SHIFT-backspace
                M-backspace: C_R-backspace
        '';
      };
    };
  };
}
