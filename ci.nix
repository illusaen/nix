let
  api = import ./default.nix;
  pkgs = import api.sources.nixpkgs.outPath {};
  rawFleet = import ./fleet;
  hive = import ./hive.nix;
  darwinConfigurations = import ./darwin.nix;
  inherit (api) nixosConfigurations;
  darwinParityFleet = let
    raw =
      rawFleet
      // {
        hosts =
          rawFleet.hosts
          // {
            test-darwin = {
              system = "aarch64-darwin";
              owner = "wendy";
              targetHost = "test-darwin.local";
              privateKey = "/etc/ssh/host_ed25519";
              hostId = "00000000";
              tags = ["darwin" "desktop" "feature:creative" "feature:dev" "feature:gaming"];
            };
          };
      };
    typed = api.libs.evalFleet raw;
  in
    typed
    // {
      hosts = api.libs.featureLib.addHostFeatures (api.libs.serviceLib.routeHosts typed);
    };
  darwinParityConfig =
    (api.libs.evalLib.mkDarwinConfigurations {fleet = darwinParityFleet;}).test-darwin.config;

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
    if
      actualHiveHosts
      == expectedHiveHosts
      && hive.huginn.deployment.targetUser == api.fleet.hosts.huginn.owner
      && hive.huginn.deployment.targetHost == api.fleet.hosts.huginn.targetHost
    then true
    else throw "hive hosts or deployment settings did not match the fleet";

  assertNixosConfigurations = let
    odinSystemPackageNames = map (pkg: pkg.name or pkg.pname or "") nixosConfigurations.odin.config.environment.systemPackages;
    odinFontPackageNames = map (pkg: pkg.name or pkg.pname or "") nixosConfigurations.odin.config.fonts.packages;
    odinGitWrapper =
      builtins.head
      (builtins.filter (pkg: (pkg.name or pkg.pname or "") == "git") nixosConfigurations.odin.config.environment.systemPackages);
    odinGitConfig = odinGitWrapper.config;
    odinHasPackageMatching = pattern: builtins.any (name: builtins.match pattern name != null) odinSystemPackageNames;
    odinHasFontPackageMatching = pattern: builtins.any (name: builtins.match pattern name != null) odinFontPackageNames;
  in
    if
      builtins.attrNames nixosConfigurations
      == expectedHiveHosts
      && nixosConfigurations.odin.config.networking.hostName == "odin"
      && nixosConfigurations.odin.config.networking.hostId == "abf835ae"
      && nixosConfigurations.odin.config.nix.settings."auto-optimise-store" == true
      && builtins.elem "@wheel" nixosConfigurations.odin.config.nix.settings."trusted-users"
      && nixosConfigurations.odin.config.security.sudo-rs.enable == true
      && nixosConfigurations.odin.config.security.sudo-rs.wheelNeedsPassword == false
      && builtins.elem "https://illusaen.cachix.org" nixosConfigurations.odin.config.nix.settings."extra-substituters"
      && nixosConfigurations.odin.config.programs.direnv.enable == true
      && builtins.elem "git" odinSystemPackageNames
      && odinGitConfig.user.email == "jaewchen@gmail.com"
      && odinGitConfig.core.sshCommand == "ssh -i /etc/ssh/host_ed25519"
      && nixosConfigurations.odin.config.hjem.users.wendy.enable == true
      && nixosConfigurations.odin.config.hjem.users.wendy.files ? ".vscode/extensions"
      && nixosConfigurations.odin.config.hjem.users.wendy.xdg.config.files ? "gh/hosts.yml"
      && nixosConfigurations.odin.config.hardware.facter.reportPath != null
      && nixosConfigurations.odin.config.nix.package.pname == "lix"
      && nixosConfigurations.odin.config.programs.nix-ld.enable == true
      && nixosConfigurations.odin.config.programs.firefox.languagePacks == ["en-US" "zh-CN"]
      && nixosConfigurations.odin.config.programs.firefox.policies.ExtensionSettings ? "uBlock0@raymondhill.net"
      && builtins.elem "starship" odinSystemPackageNames
      && nixosConfigurations.odin.config.programs.steam.enable == true
      && nixosConfigurations.odin.config.programs.zsh.enable == true
      && nixosConfigurations.odin.config.programs.zsh.shellAliases.gst == "git status"
      && builtins.match ".*dot_cd_accept_line.*" nixosConfigurations.odin.config.programs.zsh.interactiveShellInit != null
      && builtins.match ".*BETA" nixosConfigurations.odin.config.programs._1password-gui.package.name != null
      && builtins.match ".*/where_is_my_sddm_theme" nixosConfigurations.odin.config.services.displayManager.sddm.theme != null
      && nixosConfigurations.odin.config.users.users.wendy.shell.pname == "zsh"
      && builtins.elem "steam" (map (entry: entry.name) nixosConfigurations.odin.config.systemdAutostart)
      && builtins.elem "tailscale-systray" (map (entry: entry.name) nixosConfigurations.odin.config.systemdAutostart)
      && builtins.elem "viking-rise.desktop" odinSystemPackageNames
      && builtins.elem "mactahoe-cursors-2026-06-28" odinSystemPackageNames
      && builtins.elem "mactahoe-gtk-theme-2026-06-28" odinSystemPackageNames
      && builtins.elem "MacTahoe-icon-theme-2026-06-28" odinSystemPackageNames
      && builtins.elem "misc-scripts" odinSystemPackageNames
      && builtins.elem "niri-scripts" odinSystemPackageNames
      && odinHasFontPackageMatching ".*MapleMono.*"
      && odinHasPackageMatching "vscode-.*"
      && builtins.elem "sync-vscode-profiles" odinSystemPackageNames
      && nixosConfigurations.odin.config.services.llama-cpp.settings.host == "0.0.0.0"
      && nixosConfigurations.odin.config.services.llama-cpp.package.cudaSupport == true
      && nixosConfigurations.odin.config.services.openssh.enable == true
      && nixosConfigurations.odin.config.services.tailscale.enable == true
      && builtins.elem "192.168.1.161" nixosConfigurations.odin.config.programs.ssh.knownHosts.huginn.hostNames
    then true
    else throw "nixosConfigurations plain API did not evaluate as expected";

  assertDarwinConfigurations =
    if builtins.attrNames darwinConfigurations == api.libs.deployLib.darwinHostNames
    then true
    else throw "darwinConfigurations plain API did not match fleet Darwin hosts";

  assertDarwinParity = let
    caskNames = map (entry: entry.name) darwinParityConfig.homebrew.casks;
    packageNames = map (pkg: pkg.name or pkg.pname or "") darwinParityConfig.environment.systemPackages;
    gitWrapper =
      builtins.head
      (builtins.filter (pkg: (pkg.name or pkg.pname or "") == "git") darwinParityConfig.environment.systemPackages);
  in
    if
      darwinParityConfig.networking.computerName
      == "test-darwin"
      && darwinParityConfig.homebrew.enable == true
      && darwinParityConfig.homebrew.user == "wendy"
      && builtins.elem "firefox" caskNames
      && builtins.elem "codex-app" caskNames
      && builtins.elem "bambu-studio" caskNames
      && builtins.elem "steam" caskNames
      && darwinParityConfig.homebrew.masApps.Tailscale == 1475387142
      && darwinParityConfig.homebrew.masApps."Pixelmator Pro" == 1289583905
      && darwinParityConfig.programs.direnv.enable == true
      && darwinParityConfig.programs.zsh.enable == true
      && darwinParityConfig.environment.shellAliases.gst == "git status"
      && builtins.elem "starship" packageNames
      && builtins.elem "git" packageNames
      && gitWrapper.config.core.sshCommand == "ssh -i /etc/ssh/host_ed25519"
    then true
    else throw "synthetic Darwin parity configuration did not evaluate as expected";

  assertLocalPackageOverlay = let
    pkgsWithLocal = import api.sources.nixpkgs.outPath {
      system = "x86_64-linux";
      overlays = [api.overlays];
      config.allowUnfree = true;
    };
    localPackages = pkgsWithLocal.local;
    expectedPackageNames = [
      "mactahoe-cursors"
      "mactahoe-gtk-theme"
      "mactahoe-icon-theme"
      "misc-scripts"
      "niri-scripts"
    ];
  in
    if
      builtins.attrNames localPackages
      == expectedPackageNames
      && localPackages.mactahoe-cursors.pname == "mactahoe-cursors"
      && localPackages.niri-scripts.name == "niri-scripts"
    then true
    else throw "local package overlay did not expose expected packages";
in {
  plain-eval = assert assertNoFailedChecks;
  assert assertHiveHosts;
  assert assertNixosConfigurations;
  assert assertDarwinConfigurations;
  assert assertDarwinParity;
  assert assertLocalPackageOverlay;
    pkgs.runCommand "plain-fleet-eval-checks" {} ''
      touch $out
    '';
}
