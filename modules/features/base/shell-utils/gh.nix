{
  flake.modules.generic.shell-utils = {
    pkgs,
    user,
    ...
  }: {
    environment.systemPackages = [
      (pkgs.local.gh.passthru.wrap {
        _module.args = {
          inherit user;
        };
      })
    ];
  };

  flake.wrappers.gh = {
    wlib,
    lib,
    pkgs,
    config,
    ...
  }: let
    user = config._module.args.user or null;
  in {
    imports = [wlib.modules.default];
    env.GH_CONFIG_DIR = dirOf config.constructFiles.generatedConfig.path;
    package = pkgs.gh;
    constructFiles = {
      generatedConfig = {
        content = ''
          version: "1"
        '';
        relPath = "config.yml";
      };
      generatedHosts = lib.mkIf (user != null) {
        content = ''
          github.com:
            git_protocol: ssh
            users:
              ${user.identity.accountName}:
            user: ${user.identity.accountName}
        '';
        relPath = "hosts.yml";
      };
    };
  };
}
