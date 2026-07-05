_: {
  flake.moduleImports.theming = ["gtk" "runtime-theming"];

  flake.modules.nixos.theming = {
    fleet,
    pkgs,
    ...
  }: let
    inherit (fleet.theming) icon cursor;
  in {
    environment.systemPackages = [pkgs.local.${icon.packageName} pkgs.local.${cursor.packageName}];
  };
}
