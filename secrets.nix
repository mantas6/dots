let
  users = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9tV1mcJldS7nCldejKlFBtiL0Zm329wpHeccF8phEw mantas@a5"
  ];

  systems = {
    mt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1l4E2BxsfN8rHZnntHirLssQQsQ+gofyrJYo+nMWz5";
    a5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7JlqYzxa8mBF+8gZXqNaMZOviPE1W1oYaSh5xlm0r2";
    ag = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE3v1XDYC4aeX4Gwsfh0eLDv8jqKaHNzWdMA0/oso6ud";
    l4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcjt+eXqxaH4gfzXffoHoAWgRcQKDKF0xBi4DMwWKT7";
    rt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6ujinZb7QhddM/FnnViULD54DyeawSbOS2M/4/7/f9";
    tp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSSOrMr6lTDqDti6mcRZZJB1Srarf9uqqycaAZraHCm";
    pd = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5YIpKmCBnhbm5MN3hpuHaKl2MX1ggB7JRKrrCngMt9";
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
