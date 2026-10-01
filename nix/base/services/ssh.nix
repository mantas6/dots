{...}: {
  flake.modules.nixos.base = {...}: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";

        PasswordAuthentication = false;

        ChallengeResponseAuthentication = false;
        KbdInteractiveAuthentication = false;

        # Drop sessions whose client stopped answering for ~10 min
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
    };
  };
}
