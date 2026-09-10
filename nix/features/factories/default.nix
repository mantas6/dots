{lib, ...}: {
  # Library of factory aspect functions.
  # Each factory is a function that generates a parameterized module.
  options.flake.factory = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
    description = "Factory aspect functions that generate parameterized modules.";
  };
}
