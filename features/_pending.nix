name: {
  imports = [];

  modules.nixos = _: {
    warnings = [
      "feature '${name}' is registered in the plain fleet architecture but has not been migrated yet"
    ];
  };

  modules.darwin = _: {
    warnings = [
      "feature '${name}' is registered in the plain fleet architecture but has not been migrated yet"
    ];
  };
}
