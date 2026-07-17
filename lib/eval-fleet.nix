{lib}: fleetData:
(lib.evalModules {
  modules = [
    ./fleet-options.nix
    {fleet = fleetData;}
  ];
}).config.fleet
