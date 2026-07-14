let
  data = builtins.fromJSON (builtins.readFile ./sources.json);

  mkGithubSource = name: pin: let
    source = {
      inherit name;
      inherit (pin) owner repo revision;
      url = "https://github.com/${pin.owner}/${pin.repo}/archive/${pin.revision}.tar.gz";
    };
  in
    source
    // {
      outPath =
        if pin.hash == null
        then throw "npins source '${name}' does not have a hash yet"
        else
          builtins.fetchTarball {
            inherit (source) url;
            sha256 = pin.hash;
          };
    };

  mkGitlabSource = name: pin: let
    source = {
      inherit name;
      inherit (pin) owner repo revision;
      url = "https://gitlab.com/${pin.owner}/${pin.repo}/-/archive/${pin.revision}/${pin.repo}-${pin.revision}.tar.gz";
    };
    fetched =
      if pin.hash == null
      then throw "npins source '${name}' does not have a hash yet"
      else
        builtins.fetchTarball {
          inherit (source) url;
          sha256 = pin.hash;
        };
  in
    source
    // {
      outPath =
        if pin ? dir
        then fetched + "/${pin.dir}"
        else fetched;
    };

  mkSource = name: pin:
    if pin.type == "github"
    then mkGithubSource name pin
    else if pin.type == "gitlab"
    then mkGitlabSource name pin
    else throw "Unsupported npins source type '${pin.type}' for '${name}'";
in
  builtins.mapAttrs mkSource data.pins
