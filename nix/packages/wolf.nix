{...}: {
  perSystem = {
    config,
    inputs',
    ...
  }: {
    packages.wolf = inputs'.nixpkgs-go.legacyPackages.buildGoModule {
      pname = "wolf";
      version = "0.1.0";
      src = ../../opt/wolf/.;
      vendorHash = null;
    };

    apps.wolf = {
      type = "app";
      program = "${config.packages.wolf}/bin/wolf";
      meta.description = "HTTP server that sends Wake-on-LAN packets to hosts resolved from dnsmasq leases";
    };
  };
}
