{...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: let
    version = "8.0.8";
    # go.mod requires Go 1.26; nixpkgs-go pins 1.24, so build with unstable's
    # buildGoModule (Go 1.26.x) instead of inputs'.nixpkgs-go.
    goPkgs = inputs'.nixpkgs-unstable.legacyPackages;
  in {
    packages.cli-proxy-api = goPkgs.buildGoModule {
      pname = "cli-proxy-api";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "router-for-me";
        repo = "CLIProxyAPI";
        tag = "v${version}";
        hash = "sha256-FfkxVBzw3BCVUku4+U6ICC9fgmTOV7DAKUr54Ln90HM=";
      };

      vendorHash = "sha256-r3yWkdMcM40G9jV7MxW/qNv3E9WrHavFilW24quEf+8=";

      subPackages = ["cmd/server"];

      env.CGO_ENABLED = "0";

      ldflags = [
        "-s"
        "-w"
        "-X main.Version=${version}"
      ];

      postInstall = ''
        mv "$out/bin/server" "$out/bin/cli-proxy-api"
      '';

      meta = {
        description = "OpenAI/Gemini/Claude compatible proxy for CLI AI models";
        homepage = "https://github.com/router-for-me/CLIProxyAPI";
        mainProgram = "cli-proxy-api";
      };
    };
  };
}
