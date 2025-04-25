{
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    # inputs.xremap-flake.nixosModules.default
  ];

  config = lib.mkIf (lib.elem "remap" config.features) {
    # services.xremap = {
    #   /*
    #   NOTE: since this sample configuration does not have any DE, xremap needs to be started manually by systemctl --user start xremap
    #   */
    #   serviceMode = "user";
    #   userName = "mantas";
    # };
    # # Modmap for single key rebinds
    # services.xremap.config.modmap = [
    # ];
  };
}
