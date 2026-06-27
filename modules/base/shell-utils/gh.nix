{
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [pkgs.local.gh];};

  flake.wrappers = let
    accountName = "illusaen";
  in {
    gh = {
      wlib,
      pkgs,
      config,
      ...
    }: {
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
        generatedHosts = {
          content = ''
            github.com:
              git_protocol: ssh
              users:
                ${accountName}:
              user: ${accountName}
          '';
          relPath = "hosts.yml";
        };
      };
    };
  };
}
