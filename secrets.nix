let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9tV1mcJldS7nCldejKlFBtiL0Zm329wpHeccF8phEw mantas@ix"
  ];

  systems = import ./nix/_lib/systems.nix;

  allSystems = builtins.attrValues systems;

  basePath = "nix/_lib/secrets";
in {
  "${basePath}/sat-base-url.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };

  "${basePath}/test-secret.age" = {
    publicKeys = users ++ allSystems;
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
