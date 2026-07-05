{
  config,
  lib,
  ...
}: {
  systems = config.gen.composed.values.fleet.hosts |> builtins.attrValues |> map (h: h.system) |> lib.unique;
}
