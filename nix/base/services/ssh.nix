{...}: {
  flake.modules.nixos.base = {...}: {
    services.openssh = {
      enable = true;

      # Serve only the ed25519 host key. The NixOS default also offers a
      # 4096-bit RSA key, which only ancient clients need. The RSA key file
      # stays on disk; sshd just stops loading it. agenix identityPaths are
      # derived from this list and still include the ed25519 key.
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      settings = {
        PermitRootLogin = "prohibit-password";

        PasswordAuthentication = false;

        ChallengeResponseAuthentication = false;
        KbdInteractiveAuthentication = false;

        # NixOS default minus diffie-hellman-group-exchange-sha256, whose GEX
        # fallback lets very old clients negotiate a 2048-bit modulus.
        # Post-quantum hybrids stay first.
        KexAlgorithms = [
          "mlkem768x25519-sha256"
          "sntrup761x25519-sha512"
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
        ];
      };
    };
  };
}
