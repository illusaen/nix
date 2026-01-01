# This file defines overlays
{ inputs, ... }:
{
  opnix-overlay = final: _prev: {
    opnix = inputs.opnix.packages.${final.stdenv.hostPlatform.system};
  };
}
