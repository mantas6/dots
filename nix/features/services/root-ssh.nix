{...}: {
  flake.modules.nixos."services-root-ssh" = {lib, ...}: let
    keys = builtins.attrValues (import ../../_lib/users.nix).primary;
  in {
    services.openssh.settings = {
      # Key-only root login; base disables it entirely.
      PermitRootLogin = lib.mkForce "prohibit-password";
      AllowUsers = ["root"];
    };

    users.users.root.openssh.authorizedKeys.keys = keys;
  };
}
