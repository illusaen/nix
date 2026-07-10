name: {
  imports = [];

  modules.nixos = _: {
    assertions = [
      {
        assertion = false;
        message = "feature '${name}' is registered in the plain fleet architecture but has not been migrated yet";
      }
    ];
  };

  modules.darwin = _: {
    assertions = [
      {
        assertion = false;
        message = "feature '${name}' is registered in the plain fleet architecture but has not been migrated yet";
      }
    ];
  };
}
