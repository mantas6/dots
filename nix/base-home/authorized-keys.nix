{...}: {
  flake.modules.nixos.base-home = let
    keys = builtins.attrValues (import ../_lib/users.nix).others;
  in {
    users.users = {
      mantas.openssh.authorizedKeys.keys = keys;
      root.openssh.authorizedKeys.keys = keys;
    };
  };
}
