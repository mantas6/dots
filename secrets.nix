let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9tV1mcJldS7nCldejKlFBtiL0Zm329wpHeccF8phEw mantas@ix"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwmj+D1NO4kg3E6JH4ck0q+C65hTiTh69POfqXMROhF mantas@X13"
  ];

  systems = import ./nix/_lib/systems.nix;

  allSystems = builtins.attrValues systems;

  basePath = "nix/_lib/secrets";
in {
  "${basePath}/sat-base-url.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };

  "${basePath}/sat-base-url-aux.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };

  "${basePath}/sat-network.age" = {
    publicKeys = users ++ [systems.sat];
    armor = true;
  };
}
