{
  lib ? import ((import ../npins).nixpkgs.outPath + "/lib"),
  fleetLib ? import ./fleet.nix {inherit lib;},
  fleet,
}: let
  hostNames = builtins.attrNames fleet.hosts;
  nixosHosts = fleetLib.platformHosts "nixos" fleet.hosts;
  darwinHosts = fleetLib.platformHosts "darwin" fleet.hosts;

  hostsWithTag = tag:
    builtins.filter (name: builtins.elem tag (fleet.hosts.${name}.tags or [])) hostNames;

  selectHostNames = target:
    if target == "@all"
    then hostNames
    else if target == "@nixos"
    then builtins.attrNames nixosHosts
    else if target == "@darwin"
    then builtins.attrNames darwinHosts
    else if builtins.substring 0 1 target == "@"
    then hostsWithTag (builtins.substring 1 (builtins.stringLength target) target)
    else if builtins.hasAttr target fleet.hosts
    then [target]
    else throw "unknown deploy target '${target}'";
in {
  inherit darwinHosts hostNames nixosHosts selectHostNames;
  nixosHostNames = builtins.attrNames nixosHosts;
  darwinHostNames = builtins.attrNames darwinHosts;
}
