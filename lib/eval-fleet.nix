{
  lib ? import ((import ../npins).nixpkgs.outPath + "/lib"),
  modules ? [],
}: fleetData: let
  evaluated = lib.evalModules {
    modules =
      [
        ./fleet-options.nix
        {fleet = fleetData;}
      ]
      ++ modules;
  };
in
  evaluated.config.fleet
