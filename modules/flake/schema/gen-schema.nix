{inputs, ...}: {
  flake-file.inputs.gen-schema.url = "github:sini/gen-schema";
  imports = [inputs.gen-schema.flakeModules.default];
}
