{
  inputs,
  lib,
  ...
}: let
  genSchema = inputs.gen-schema.lib;
in {
  schema.service.options = {config, ...}: {
    port = lib.mkOption {
      type = lib.types.int;
      description = "Service port number";
    };
    protocol = lib.mkOption {
      type = lib.types.enum ["tcp" "udp" "http" "https"];
      description = "Network protocol";
      default = "tcp";
    };
    host = lib.mkOption {
      type = genSchema.ref "host";
      description = "Host this service runs on";
    };
    backups = lib.mkOption {
      type = genSchema.setOf (genSchema.ref "host");
      default = [];
      description = "Hosts this service also runs on - the service's host is automatically removed";
      apply = value: lib.filter (h: h.id_hash != config.host.id_hash) value;
    };
  };

  schema.service.validators = [
    (genSchema.mkFieldValidator {
      name = "https-port";
      fields = [
        "port"
        "protocol"
      ];
      check = inst: !(inst.protocol == "https" && inst.port == 80);
      message = "HTTPS should not use port 80";
    })
    (genSchema.mkValidator "valid-port" (
      {port, ...}: port > 0 && port < 65536
    ) "port must be between 1 and 65535")
  ];
}
