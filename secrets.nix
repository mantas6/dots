let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9tV1mcJldS7nCldejKlFBtiL0Zm329wpHeccF8phEw mantas@a5"
  ];

  systems = {
    mt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1l4E2BxsfN8rHZnntHirLssQQsQ+gofyrJYo+nMWz5";
    # TODO: replace with l4's real host key: `cat /etc/ssh/ssh_host_ed25519_key.pub` on l4
    l4 = "ssh-ed25519 REPLACE_WITH_L4_HOST_PUBKEY";
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

  # SSH private key l4 uses to pull /var/lib/hermes from rt (read-only).
  "${basePath}/hermes-backup-key.age" = {
    publicKeys = users ++ [systems.l4];
    armor = true;
  };
}
