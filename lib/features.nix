_: let
  inherit (builtins) attrNames filter hasAttr map readDir;

  featureRoot = ../features;

  featureNames =
    filter (name: (readDir featureRoot).${name} == "directory")
    (attrNames (readDir featureRoot));

  loadFeature = name: import (featureRoot + "/${name}") {};

  features = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = loadFeature name;
    })
    featureNames
  );

  close = names: let
    go = seen: pending:
      if pending == []
      then seen
      else let
        name = builtins.head pending;
        rest = builtins.tail pending;
        feature =
          if hasAttr name features
          then features.${name}
          else throw "unknown feature '${name}'";
        next = feature.imports or [];
      in
        if builtins.elem name seen
        then go seen rest
        else go (seen ++ [name]) (rest ++ next);
  in
    go [] names;

  modulesFor = platform: names:
    map (name: features.${name}.modules.${platform})
    (filter (name: (features.${name}.modules.${platform} or null) != null) (close names));

  missingFeatures = names: filter (name: !(hasAttr name features)) names;

  missingPlatformModules = platform: names:
    filter (
      name:
        hasAttr name features
        && (features.${name}.modules.${platform} or null) == null
    )
    names;
in {
  inherit close featureNames features missingFeatures missingPlatformModules modulesFor;
}
