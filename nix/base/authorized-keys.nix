{...}: {
  flake.modules.nixos.base = let
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwmj+D1NO4kg3E6JH4ck0q+C65hTiTh69POfqXMROhF mantas@X13"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC5k7rbC+vefo20If2RHDFMxztdC6tkeUaN88tentEeh mantas@MacBookPro.lan"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOLvKAVZSLkt8QQ8W0ZgDs4yzwB6rFQpO0F9W68FPL6 mantas@w"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9tV1mcJldS7nCldejKlFBtiL0Zm329wpHeccF8phEw mantas@a5"
    ];
  in {
    users.users = {
      mantas.openssh.authorizedKeys.keys = keys;
      root.openssh.authorizedKeys.keys = keys;
    };
  };
}
