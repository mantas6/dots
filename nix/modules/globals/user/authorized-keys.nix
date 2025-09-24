let
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtMJ6SP+1ppYvlbRSDyjhmWvDFOvKGFMD7V88h7Q6Ni mantas@amd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwmj+D1NO4kg3E6JH4ck0q+C65hTiTh69POfqXMROhF mantas@X13"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC5k7rbC+vefo20If2RHDFMxztdC6tkeUaN88tentEeh mantas@MacBookPro.lan"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJO2Vhr1xayCvuo+GT3lP3VCcpgaIR4z6TlFGLwex7yv mantas@ix"
  ];
in {
  users.users = {
    mantas.openssh.authorizedKeys.keys = keys;
    root.openssh.authorizedKeys.keys = keys;
  };
}
