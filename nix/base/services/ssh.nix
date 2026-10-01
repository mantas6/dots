{...}: {
  flake.modules.nixos.base = {...}: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";

        PasswordAuthentication = false;

        ChallengeResponseAuthentication = false;
        KbdInteractiveAuthentication = false;

        # Tighter than OpenSSH defaults (6, 120, 10:30:100) to cut brute-force cost on public hosts
        MaxAuthTries = 3;
        LoginGraceTime = 30;
        MaxStartups = "10:30:60";
      };
    };
  };
}
