let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9tV1mcJldS7nCldejKlFBtiL0Zm329wpHeccF8phEw mantas@a5"
  ];

  systems = {
    mt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1l4E2BxsfN8rHZnntHirLssQQsQ+gofyrJYo+nMWz5";
    a5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7JlqYzxa8mBF+8gZXqNaMZOviPE1W1oYaSh5xlm0r2";
  };

  allSystems = builtins.attrValues systems;

  basePath = "lib/secrets";
in {
  "${basePath}/sat-base-url.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };

  "${basePath}/test-secret.age" = {
    publicKeys = users ++ allSystems;
    armor = true;
  };
}
