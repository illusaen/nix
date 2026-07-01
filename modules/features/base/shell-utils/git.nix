{
  flake.modules.generic.shell-utils = {
    pkgs,
    host,
    user,
    ...
  }: {
    environment.systemPackages = [
      (pkgs.local.git.passthru.wrap {
        _module.args = {
          inherit host user;
        };
      })
    ];
  };

  flake.wrappers.git = {
    wlib,
    lib,
    pkgs,
    config,
    ...
  }: let
    host = config._module.args.host or null;
    user = config._module.args.user or null;
    hasHostUser = host != null && user != null;
  in {
    imports = [wlib.wrapperModules.git];
    runtimePkgs = with pkgs; [difftastic];
    settings = lib.mkIf hasHostUser {
      core.sshCommand = "ssh -i ${host.privateKey}";
      diff.external = "difft --color auto --background dark --display side-by-side";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      user = {
        inherit (user.identity) email;
        name = user.identity.displayName;
      };
      credential = {
        inherit (user.identity) accountName;
        helper = "!gh auth git-credential";
      };
    };
  };
}
