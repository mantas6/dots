# Private network between own devices
# Log in once with `sudo tailscale up`; the state is kept in /var/lib/tailscale
{...}: {
  flake.modules.nixos."services-tailscale" = {config, ...}: {
    services.tailscale = {
      enable = true;
      # WireGuard port, so peers connect directly instead of through a relay
      openFirewall = true;
    };

    # Devices on the tailnet reach every port of this host
    networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];
  };
}
