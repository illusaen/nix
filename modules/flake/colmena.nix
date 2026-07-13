{
  inputs,
  genValues,
  self,
  ...
}: {
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
    // (genValues.fleet.hosts
      |> builtins.mapAttrs (h: v: {
        deployment = {
          targetHost = "${h}.${genValues.fleet.domain}";
          targetUser = "root";
          buildOnTarget = false;
          tags = [v.tags.role];
        };
        imports = [self.nixosConfigurations.${h}.config.system.build.toplevel];
      })));
}
