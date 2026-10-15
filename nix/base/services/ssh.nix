{...}: {
  flake.modules.nixos.base = {...}: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";

        PasswordAuthentication = false;

        ChallengeResponseAuthentication = false;
        KbdInteractiveAuthentication = false;

        # The only account that holds authorized keys.
        AllowUsers = ["mantas"];
      };
    };
  };
}
