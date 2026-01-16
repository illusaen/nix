# This file defines overlays
{ inputs, ... }:
final: _prev: {
  zmk-studio = final.callPackage ../packages/zmk-studio.nix { };
}
