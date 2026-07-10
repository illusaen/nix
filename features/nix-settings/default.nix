{...}: {
  imports = [];

  modules.nixos = {fleet, ...}: {
    nix.settings = {
      accept-flake-config = true;
      experimental-features = ["nix-command" "flakes" "pipe-operator" "pipe-operators"];
      warn-dirty = false;
    };
    time.timeZone = fleet.timeZone;
  };

  modules.darwin = {fleet, ...}: {
    nix.settings = {
      accept-flake-config = true;
      experimental-features = ["nix-command" "flakes" "pipe-operator" "pipe-operators"];
      warn-dirty = false;
    };
    time.timeZone = fleet.timeZone;
  };
}
