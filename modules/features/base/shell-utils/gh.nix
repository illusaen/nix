{
  flake.modules.generic.shell-utils = {pkgs, ...}: {environment.systemPackages = [pkgs.local.gh];};

  flake.wrappers.gh = {
    wlib,
    pkgs,
    config,
    ...
  }: let
    accountName = "illusaen";
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
}
