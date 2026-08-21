{
  fleetLib,
  fleet,
}: let
  hostNames = builtins.attrNames fleet.hosts;
  nixosHosts = fleetLib.platformHosts "nixos" fleet.hosts;
  nixosHostNames = builtins.attrNames nixosHosts;
  darwinHostNames = builtins.attrNames (fleetLib.platformHosts "darwin" fleet.hosts);

  hostsWithTag = tag:
    builtins.filter (name: builtins.elem tag (fleet.hosts.${name}.tags or [])) hostNames;
in {
  inherit darwinHostNames nixosHosts;
  selectHostNames = target:
    if target == "@all"
    then hostNames
    else if target == "@nixos"
    then nixosHostNames
    else if target == "@darwin"
    then darwinHostNames
    else if builtins.substring 0 1 target == "@"
    then hostsWithTag (builtins.substring 1 (builtins.stringLength target) target)
    else if builtins.hasAttr target fleet.hosts
    then [target]
    else throw "unknown deploy target '${target}'";
}
