# Upstream's prebuilt FrankenPHP release (embedded ZTS PHP, glibc build),
# patched to run on NixOS. Not a flake-parts module: the underscore keeps
# import-tree away, and callers pass in their PHP ini via `phpExtraConfig`.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  cacert,
  writeTextDir,
  phpExtraConfig ? "",
}: let
  caBundle = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  # The embedded OpenSSL looks for /etc/ssl/cert.pem, which NixOS lacks.
  iniDir = writeTextDir "frankenphp.ini" ''
    openssl.cafile = ${caBundle}
    curl.cainfo = ${caBundle}

    ${phpExtraConfig}
  '';
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "frankenphp-bin";
    version = "1.12.7";

    src = fetchurl {
      url = "https://github.com/php/frankenphp/releases/download/v${finalAttrs.version}/frankenphp-linux-x86_64-gnu";
      hash = "sha256-BFKJa32q8VQKkJujX4YMRMLrAqqgEXcPEGHGPItiYz8=";
    };

    dontUnpack = true;
    dontStrip = true;

    nativeBuildInputs = [autoPatchelfHook makeWrapper];
    buildInputs = [stdenv.cc.cc.lib];

    # Setting (not unsetting) the scan dir also shadows the one exported by the
    # nix php CLI wrapper, whose extension .so files the binary can't load.
    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/libexec/frankenphp
      makeWrapper $out/libexec/frankenphp $out/bin/frankenphp \
        --set PHP_INI_SCAN_DIR ${iniDir}
      runHook postInstall
    '';

    meta = {
      description = "Modern PHP app server built on Caddy (upstream prebuilt binary)";
      homepage = "https://frankenphp.dev";
      license = lib.licenses.mit;
      mainProgram = "frankenphp";
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  })
