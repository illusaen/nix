{
  config,
  lib,
  ...
}: {
  systems = config.fleet.hosts |> builtins.attrValues |> map (h: h.system) |> lib.unique;
}
