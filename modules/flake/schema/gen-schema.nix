{
  inputs,
  config,
  ...
}: {
  flake-file.inputs.gen-schema.url = "github:sini/gen-schema";
  imports = [inputs.gen-schema.flakeModules.default];

  perSystem.files.file."docs/gen/schema.md".text = let inherit (inputs.gen-schema.lib) renderDocs; in renderDocs config.schema;
}
