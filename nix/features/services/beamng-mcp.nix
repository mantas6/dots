{...}: {
  flake.modules.nixos."services-beamng-mcp" = {pkgs, ...}: let
    port = 29293;
  in {
    # BeamNG's built-in MCP server only listens on 127.0.0.1:29292,
    # so relay it to the LAN (no auth, keep the range tight)
    systemd.services.beamng-mcp-proxy = {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:${toString port},fork,reuseaddr,range=10.0.1.0/24 TCP:127.0.0.1:29292";
        DynamicUser = true;
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = [port];
  };
}
