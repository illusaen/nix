{
  lib,
  config,
  genSchema,
  ...
}: let
  inherit (lib) mkOption;
  inherit (lib.types) str;

  mkSingletonInstanceOption = kindValue: args:
    mkOption {
      type = genSchema.mkInstanceType kindValue (removeAttrs args ["default" "description"]);
      default = args.default or {};
      description = args.description or "${kindValue.kind} singleton instance";
      apply = value: let
        result = genSchema.validateInstances kindValue {
          ${kindValue.kind} = value;
        };
      in
        if result ? right
        then result.right.${kindValue.kind}
        else throw "schema validation failed:\n${genSchema.formatErrors result.left}";
    };
in {
  options.fleet = mkSingletonInstanceOption config.schema.fleet {
    description = "Singleton fleet instance.";
  };

  config.schema.fleet.validators = [
    (genSchema.mkValidator "domain-not-empty" ({domain, ...}:
        domain != "") "fleet domain must not be empty")
  ];

  config.schema.fleet.options = {
    domain = mkOption {
      type = str;
      description = "Base domain for the fleet";
    };

    timeZone = mkOption {
      type = str;
      default = "CST";
      description = "Default timezone for the fleet";
    };
  };

  config.fleet = {
    domain = "home.arpa";
    timeZone = "America/Chicago";
  };
}
