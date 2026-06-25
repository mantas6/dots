{inputs, ...}: {
  flake.nixosModules."other-secrets" = {...}: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    age.secrets = {
      sat-base-url.file = ../../../secrets/sat-base-url.age;
    };
  };
}
