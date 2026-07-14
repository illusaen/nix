let
  api = import ./default.nix;
  pkgs = import api.sources.nixpkgs.outPath {};
  hive = import ./hive.nix;
  darwinConfigurations = import ./darwin.nix;
  nixosConfigurations = api.hostLib.mkNixosConfigurations {
    inherit (api) fleet sources;
  };
  darwinParityFleet =
    api.fleet
    // {
      hosts.test-darwin = {
        platform = "darwin";
        system = "aarch64-darwin";
        owner = "wendy";
        targetHost = "test-darwin.local";
        privateKey = "/etc/ssh/ssh_host_ed25519_key";
        hostId = "00000000";
        tags = ["darwin" "desktop" "feature:dev"];
        features = [
          "base"
          "wendy"
          "desktop-shell"
          "programs-core"
          "programs-creative"
          "programs-dev"
          "programs-gaming"
          "theming"
        ];
      };
    };
  darwinParityConfig =
    (api.hostLib.mkDarwinConfigurations {
      fleet = darwinParityFleet;
      inherit (api) sources;
    }).test-darwin.config;

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
    odinHasPackageMatching = pattern: builtins.any (name: builtins.match pattern name != null) odinSystemPackageNames;
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
      && nixosConfigurations.odin.config.hjem.users.wendy.enable == true
      && nixosConfigurations.odin.config.hjem.users.wendy.files ? ".vscode/extensions"
      && nixosConfigurations.odin.config.hjem.users.wendy.xdg.config.files ? "gh/hosts.yml"
      && nixosConfigurations.odin.config.hardware.facter.reportPath != null
      && nixosConfigurations.odin.config.nix.package.pname == "lix"
      && nixosConfigurations.odin.config.programs.nix-ld.enable == true
      && nixosConfigurations.odin.config.programs.firefox.languagePacks == ["en-US" "zh-CN"]
      && nixosConfigurations.odin.config.programs.firefox.policies.ExtensionSettings ? "uBlock0@raymondhill.net"
      && nixosConfigurations.odin.config.programs.starship.enable == true
      && nixosConfigurations.odin.config.programs.steam.enable == true
      && nixosConfigurations.odin.config.programs.zsh.enable == true
      && nixosConfigurations.odin.config.programs.zsh.shellAliases.gst == "git status"
      && builtins.match ".*dot_cd_accept_line.*" nixosConfigurations.odin.config.programs.zsh.interactiveShellInit != null
      && builtins.match ".*BETA" nixosConfigurations.odin.config.programs._1password-gui.package.name != null
      && builtins.match ".*/where_is_my_sddm_theme" nixosConfigurations.odin.config.services.displayManager.sddm.theme != null
      && nixosConfigurations.odin.config.users.users.wendy.shell.pname == "zsh"
      && builtins.elem "steam" (map (entry: entry.name) nixosConfigurations.odin.config.systemdAutostart)
      && builtins.elem "viking-rise.desktop" odinSystemPackageNames
      && builtins.elem "mactahoe-cursors-2026-06-28" odinSystemPackageNames
      && builtins.elem "mactahoe-gtk-theme-2026-06-28" odinSystemPackageNames
      && builtins.elem "MacTahoe-icon-theme-2026-06-28" odinSystemPackageNames
      && odinHasPackageMatching ".*MapleMono.*"
      && odinHasPackageMatching "vscode-.*"
      && builtins.elem "sync-vscode-profiles" odinSystemPackageNames
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

  assertDarwinParity = let
    caskNames = map (entry: entry.name) darwinParityConfig.homebrew.casks;
  in
    if
      darwinParityConfig.networking.computerName
      == "test-darwin.local"
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
      && builtins.match ".*STARSHIP_CONFIG.*" darwinParityConfig.programs.zsh.interactiveShellInit != null
      && builtins.match ".*sshCommand = \"ssh -i /etc/ssh/ssh_host_ed25519_key\".*" darwinParityConfig.environment.etc.gitconfig.text != null
    then true
    else throw "synthetic Darwin parity configuration did not evaluate as expected";

  assertPackages = let
    packages = api.packages.x86_64-linux;
  in
    if
      builtins.attrNames packages
      == api.packageLib.packageNames
      && packages.mactahoe-cursors.pname == "mactahoe-cursors"
      && packages.niri-scripts.name == "niri-scripts"
    then true
    else throw "plain package API did not expose expected local packages";
in {
  plain-eval = assert assertNoFailedChecks;
  assert assertHiveHosts;
  assert assertNixosConfigurations;
  assert assertDarwinConfigurations;
  assert assertDarwinParity;
  assert assertPackages;
    pkgs.runCommand "plain-fleet-eval-checks" {} ''
      touch $out
    '';
}
