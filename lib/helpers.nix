{ lib }:
{
  mkTrueOption = name: lib.mkEnableOption name // { default = true; };
}
