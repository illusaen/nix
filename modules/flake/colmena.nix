{
  inputs,
  genValues,
  lib,
  self,
  ...
}: let
  inherit (genValues) fleet;
  nixosHosts = lib.filterAttrs (_name: host: host.class == "nixos") fleet.hosts;

  mkDeployment = name: host: {
    deployment = {
      targetHost = "${name}.${fleet.domain}";
      targetUser = host.owner.name or host.owner;
      buildOnTarget = false;
      tags = [host.tags.role];
    };
  };

  mkNode = name: host: {
    imports = self.nixosConfigurations.${name}._module.args.modules;
    _module.args = {
      inherit fleet self;
      inherit (host) owner;
      host = self.nixosConfigurations.${name}._module.specialArgs.host or host;
      user = host.owner;
    };
  };
in {
  flake-file.inputs.colmena = {
    url = "github:zhaofengli/colmena";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  flake-file.nixConfig = {
    extra-substituters = ["https://colmena.cachix.org"];
    extra-trusted-public-keys = [
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];
  };

  flake.colmenaHive = inputs.colmena.lib.makeHive ({
      meta.nixpkgs = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    }
    // builtins.mapAttrs (name: host:
      mkNode name host // mkDeployment name host)
    nixosHosts);
}
