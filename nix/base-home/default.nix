{...}: {
  flake.modules.nixos.base-home = {lib, ...}: {
    users.users.mantas = {
      # mkpasswd
      hashedPassword = lib.mkDefault "$y$j9T$ZhKXn9KIagbM2wzlkOXfz/$RQmrNYqwkbYre0BgLJ83nCHAWr6e/QCABtax5gXN6k.";

      # serial access
      extraGroups = ["dialout"];
    };

    networking.firewall.enable = false;
  };
}
