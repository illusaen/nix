# This file defines overlays
{ inputs, ... }:
final: _prev: {
  opnix = inputs.opnix.packages.${final.stdenv.hostPlatform.system};
}
