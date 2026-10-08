{...}: {
  perSystem = {pkgs, ...}: {
    # Upstream's prebuilt release (static-pie), since building from source
    # needs a Rust + Zig toolchain and there is no nixpkgs package.
    packages.herdr = pkgs.callPackage ({
      lib,
      stdenvNoCC,
      fetchurl,
    }:
      stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "herdr";
        version = "0.9.3";

        src = fetchurl {
          url = "https://github.com/herdrdev/herdr/releases/download/v${finalAttrs.version}/herdr-linux-x86_64";
          hash = "sha256-GKjcZfHC+khYhDRDVt6hz9kRxvBs9G+njhk/QIf026c=";
        };

        dontUnpack = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          install -Dm755 $src $out/bin/herdr
          runHook postInstall
        '';

        meta = {
          description = "Terminal workspace manager for AI coding agents (upstream prebuilt binary)";
          homepage = "https://herdr.dev";
          license = lib.licenses.asl20;
          mainProgram = "herdr";
          platforms = ["x86_64-linux"];
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        };
      })) {};
  };
}
