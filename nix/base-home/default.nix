{...}: {
  flake.nixosModules.base-home = {...}: {
    users.users.mantas = {
      # mkpasswd
      hashedPassword = "$y$j9T$ZhKXn9KIagbM2wzlkOXfz/$RQmrNYqwkbYre0BgLJ83nCHAWr6e/QCABtax5gXN6k.";
    };

    networking.firewall.enable = false;
  };
}
