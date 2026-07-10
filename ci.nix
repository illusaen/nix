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

  assertNixosConfigurations = let
    odinGitConfig = builtins.head nixosConfigurations.odin.config.programs.git.config;
    odinSystemPackageNames = map (pkg: pkg.name or pkg.pname or "") nixosConfigurations.odin.config.environment.systemPackages;
  in
    if
      builtins.attrNames nixosConfigurations
      == expectedHiveHosts
      && nixosConfigurations.odin.config.networking.hostName == "odin"
      && nixosConfigurations.odin.config.nix.settings."auto-optimise-store" == true
      && builtins.elem "@wheel" nixosConfigurations.odin.config.nix.settings."trusted-users"
      && builtins.elem "https://illusaen.cachix.org" nixosConfigurations.odin.config.nix.settings."extra-substituters"
      && nixosConfigurations.odin.config.programs.direnv.enable == true
      && nixosConfigurations.odin.config.programs.git.enable == true
      && odinGitConfig.user.email == "jaewchen@gmail.com"
      && odinGitConfig.core.sshCommand == "ssh -i /etc/ssh/ssh_host_ed25519_key"
      && nixosConfigurations.odin.config.programs.nix-ld.enable == true
      && nixosConfigurations.odin.config.programs.starship.enable == true
      && nixosConfigurations.odin.config.programs.steam.enable == true
      && nixosConfigurations.odin.config.programs.zsh.enable == true
      && nixosConfigurations.odin.config.programs.zsh.shellAliases.gst == "git status"
      && nixosConfigurations.odin.config.users.users.wendy.shell.pname == "zsh"
      && builtins.elem "steam" (map (entry: entry.name) nixosConfigurations.odin.config.systemdAutostart)
      && builtins.elem "viking-rise.desktop" odinSystemPackageNames
      && nixosConfigurations.odin.config.services.llama-cpp.settings.host == "0.0.0.0"
      && nixosConfigurations.odin.config.services.openssh.enable == true
      && nixosConfigurations.odin.config.services.tailscale.enable == true
      && builtins.elem "192.168.1.164" nixosConfigurations.odin.config.programs.ssh.knownHosts.huginn.hostNames
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
