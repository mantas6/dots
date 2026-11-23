{...}: {
  flake.modules.nixos."services-mysql" = {pkgs, ...}: {
    # Dev-only server, bound to localhost; users auth via auth_socket (no passwords)
    services.mysql = {
      enable = true;
      # mysql80 is EOL and removed from nixpkgs; 8.4 is the current MySQL LTS
      package = pkgs.mysql84;
      settings.mysqld.bind-address = "127.0.0.1";
      ensureUsers = [
        {
          name = "mantas";
          ensurePermissions = {"*.*" = "ALL PRIVILEGES";};
        }
      ];
    };
  };
}
