{...}: {
  perSystem = {pkgs, ...}: {
    # Upstream's prebuilt CLIProxyAPI release. The linux `no-plugin` builds are
    # static Go binaries, so they run on NixOS without patching. Chosen over a
    # source build to avoid needing the Go 1.26 toolchain from nixpkgs-unstable.
    packages.cli-proxy-api = pkgs.callPackage ({
      lib,
      stdenv,
      fetchurl,
    }: let
      sources = {
        x86_64-linux = {
          variant = "linux_amd64_no-plugin";
          hash = "sha256-IZKWhuuO20Bvjqm7FhmY9ErQpFtslACOQwxQWfpRWnA=";
        };
        aarch64-linux = {
          variant = "linux_aarch64_no-plugin";
          hash = "sha256-+xY/Vd7bQt1DCGONIKB3HGDdukqfxZBIMW5sLrFLGOw=";
        };
        aarch64-darwin = {
          variant = "darwin_aarch64";
          hash = "sha256-30j+am5cYNGWbtN05rBWfLjIcYDfndFN+yX0I2W0uyU=";
        };
        x86_64-darwin = {
          variant = "darwin_amd64";
          hash = "sha256-ZUmgEOGPNKXXBGTx73z1UG70Ow4mCyZswIaf5Rn7nTQ=";
        };
      };

      inherit
        (sources.${stdenv.hostPlatform.system}
          or (throw "cli-proxy-api: unsupported system ${stdenv.hostPlatform.system}"))
        variant
        hash
        ;
    in
      stdenv.mkDerivation (finalAttrs: {
        pname = "cli-proxy-api";
        version = "8.0.8";

        src = fetchurl {
          url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${finalAttrs.version}/CLIProxyAPI_${finalAttrs.version}_${variant}.tar.gz";
          inherit hash;
        };

        sourceRoot = ".";

        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          install -Dm755 cli-proxy-api $out/bin/cli-proxy-api
          install -Dm644 config.example.yaml $out/share/cli-proxy-api/config.example.yaml
          runHook postInstall
        '';

        meta = {
          description = "OpenAI/Gemini/Claude compatible proxy for CLI AI models (upstream prebuilt binary)";
          homepage = "https://github.com/router-for-me/CLIProxyAPI";
          license = lib.licenses.mit;
          mainProgram = "cli-proxy-api";
          platforms = lib.attrNames sources;
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        };
      })) {};
  };
}
