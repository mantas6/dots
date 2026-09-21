let
  users = builtins.attrValues (import ./nix/_lib/users.nix).primary;

  systems = import ./nix/_lib/systems.nix;

  allSystems = builtins.attrValues systems;

  basePath = "nix/_lib/secrets";
in {
  "${basePath}/sat-base-url.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };

  "${basePath}/sat-caddy-env.age" = {
    publicKeys = users ++ [systems.sat];
    armor = true;
  };

  "${basePath}/sat-network.age" = {
    publicKeys = users ++ [systems.sat];
    armor = true;
  };

  "${basePath}/dashboard-token.age" = {
    publicKeys = users ++ [systems.l4];
    armor = true;
  };

  "${basePath}/cli-proxy-api-keys.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };

  "${basePath}/cli-proxy-mgmt-key.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };
}
