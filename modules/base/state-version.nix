{
  flake.modules.nixos.state-version = {
    system.stateVersion = "26.11";
  };

  flake.modules.darwin.state-version = {
    system.stateVersion = "6";
  };
}
