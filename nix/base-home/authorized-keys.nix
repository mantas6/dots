{...}: {
  flake.modules.nixos.base-home = let
    keys = with import ../_lib/users.nix; [mbp w];
  in {
    users.users = {
      mantas.openssh.authorizedKeys.keys = keys;
      root.openssh.authorizedKeys.keys = keys;
    };
  };
}
