{self, ...}: {
  perSystem = {
    pkgs,
    system,
    lib,
    ...
  }: let
    host = self.nixosConfigurations.rt.config;
    hermes = host.services.hermes-agent;
    unstable = self.inputs.nixpkgs-unstable.legacyPackages.${system};
    chromium = "${unstable.chromium}/bin/chromium";
    gateway = host.systemd.services.hermes-agent;
  in {
    checks.hermes-runtime = assert lib.assertMsg (hermes.settings.model.provider or "" == "openai-codex") "Hermes must explicitly use openai-codex";
    assert lib.assertMsg (hermes.settings.browser.executable_path or "" == chromium) "Hermes must use Nix Chromium rather than the migrated generic Linux binary";
    assert lib.assertMsg (hermes.settings.web.extract_backend or "" == "parallel") "Hermes must select an extraction-capable web backend";
    assert lib.assertMsg (hermes.settings.web.provider_tier.parallel or "" == "free") "Hermes extraction must not require a paid API key";
    assert lib.assertMsg (builtins.elem unstable.chromium hermes.extraPackages) "Nix Chromium must remain in the Hermes user profile";
    assert lib.assertMsg (builtins.elem unstable.pnpm hermes.extraPackages) "pnpm must be available to Hermes";
    assert lib.assertMsg (builtins.elem unstable.pnpm gateway.path) "pnpm must be on the gateway PATH";
    assert lib.assertMsg (builtins.elem unstable.pnpm host.users.users.hermes.packages) "pnpm must be in the Hermes login profile";
      pkgs.runCommand "hermes-runtime-config" {} ''
        echo "PASS: Hermes provider, Nix Chromium, keyless extraction and pnpm configuration"
        touch "$out"
      '';
  };
}
