{inputs, ...}: {
  flake.nixosModules."other-secrets" = {...}: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    age.secrets = {
      sat-base-url = {
        file = ./sat-base-url.age;
        owner = "mantas";
      };
    };
  };
}
