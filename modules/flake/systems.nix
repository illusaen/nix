{
  lib,
  genValues,
  ...
}: {
  systems = genValues.fleet.hosts |> builtins.attrValues |> map (h: h.system) |> lib.unique;
}
