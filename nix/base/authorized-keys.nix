{...}: {
  flake.modules.nixos.base = let
    keys = builtins.attrValues (import ../_lib/users.nix);
  in {
    users.users = {
      mantas.openssh.authorizedKeys.keys = keys;
      root.openssh.authorizedKeys.keys = keys;
    };
  };
}
