let
  api = import ./default.nix;
  pkgs = import api.sources.nixpkgs.outPath {};
  hive = import ./hive.nix;

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
in {
  plain-eval = assert assertNoFailedChecks;
  assert assertHiveHosts;
    pkgs.runCommand "plain-fleet-eval-checks" {} ''
      touch $out
    '';
}
