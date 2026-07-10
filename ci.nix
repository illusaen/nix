let
  api = import ./default.nix;
  pkgs = import api.sources.nixpkgs.outPath {};
  hive = import ./hive.nix;
  darwinConfigurations = import ./darwin.nix;
  nixosConfigurations = api.hostLib.mkNixosConfigurations {
    inherit (api) fleet sources;
  };

  failedChecks =
    builtins.filter (name: api.checks.${name} != true)
    (builtins.attrNames api.checks);

  expectedHiveHosts = ["huginn" "muninn" "odin"];
  actualHiveHosts = builtins.filter (name: name != "meta") (builtins.attrNames hive);

  assertNoFailedChecks =
    if failedChecks == []
    then true
    else throw "plain fleet checks failed: ${builtins.concatStringsSep ", " failedChecks}";

  assertHiveHosts =
    if actualHiveHosts == expectedHiveHosts
    then true
    else throw "hive hosts mismatch: expected ${builtins.toJSON expectedHiveHosts}, got ${builtins.toJSON actualHiveHosts}";

  assertNixosConfigurations =
    if
      builtins.attrNames nixosConfigurations
      == expectedHiveHosts
      && nixosConfigurations.odin.config.networking.hostName == "odin"
      && nixosConfigurations.odin.config.services.llama-cpp.settings.host == "0.0.0.0"
    then true
    else throw "nixosConfigurations plain API did not evaluate as expected";

  assertDarwinConfigurations =
    if builtins.attrNames darwinConfigurations == api.deploy.darwinHostNames
    then true
    else throw "darwinConfigurations plain API did not match fleet Darwin hosts";
in {
  plain-eval = assert assertNoFailedChecks;
  assert assertHiveHosts;
  assert assertNixosConfigurations;
  assert assertDarwinConfigurations;
    pkgs.runCommand "plain-fleet-eval-checks" {} ''
      touch $out
    '';
}
