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
          hash = "sha256-SeqX0lCaRjAGvxvV7YL95oLAB0RMli8T4dSzpPW8GWA=";
        };
        aarch64-linux = {
          variant = "linux_aarch64_no-plugin";
          hash = "sha256-c7WObmUD1wIy7By+lb5MuP/AYBJwGWNZad72zrEtLsI=";
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
        version = "8.0.41";

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
