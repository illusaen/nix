{lib}: let
  inherit (builtins) attrNames concatStringsSep isAttrs isBool isFloat isFunction isInt isList isString map;

  indent = level: concatStringsSep "" (builtins.genList (_: "  ") level);

  validIdentifier = name: builtins.match "[A-Za-z_][A-Za-z0-9_-]*" name != null;

  renderName = name:
    if validIdentifier name
    then name
    else builtins.toJSON name;

  renderScalar = value:
    if isString value
    then builtins.toJSON value
    else if isBool value
    then lib.boolToString value
    else if isInt value || isFloat value
    then toString value
    else throw "cannot render KDL scalar value";

  normalize = value:
    if isFunction value
    then value null
    else value;

  normalizeProps = props:
    if isList props
    then builtins.foldl' (merged: next: merged // next) {} props
    else props;

  renderProp = name: value: "${renderName name}=${renderScalar (normalize value)}";

  renderProps = props:
    if props == {}
    then ""
    else " " + concatStringsSep " " (map (name: renderProp name props.${name}) (attrNames props));

  renderArgs = args:
    if args == []
    then ""
    else " " + concatStringsSep " " (map (value: renderScalar (normalize value)) args);

  renderNode = level: name: rawValue: let
    value = normalize rawValue;
    pad = indent level;
  in
    if isAttrs value
    then let
      props = normalizeProps (value.props or {});
      args = value.args or [];
      children = builtins.removeAttrs value ["args" "props"];
      childText = renderAttrs (level + 1) children;
    in
      if childText == ""
      then "${pad}${renderName name}${renderArgs args}${renderProps props}"
      else ''
        ${pad}${renderName name}${renderArgs args}${renderProps props} {
        ${childText}
        ${pad}}''
    else if isList value
    then
      if builtins.all (element: isAttrs (normalize element)) value
      then ''
        ${pad}${renderName name} {
        ${concatStringsSep "\n" (map (element: renderAttrs (level + 1) (normalize element)) value)}
        ${pad}}''
      else concatStringsSep "\n" (map (element: renderNode level name element) value)
    else "${pad}${renderName name} ${renderScalar value}";

  renderAttrs = level: attrs:
    concatStringsSep "\n" (map (name: renderNode level name attrs.${name}) (attrNames attrs));

  renderNamedAttrset = level: nodeName: attrs:
    concatStringsSep "\n" (map (name: renderNode level nodeName ({args = [name];} // attrs.${name})) (attrNames attrs));

  renderMatch = level: match:
    renderNode level "match" {props = match;};

  renderRule = level: nodeName: rule: let
    pad = indent level;
    body = builtins.removeAttrs rule ["matches"];
    matchText = concatStringsSep "\n" (map (renderMatch (level + 1)) (rule.matches or []));
    bodyText = renderAttrs (level + 1) body;
    childText = concatStringsSep "\n" (builtins.filter (part: part != "") [matchText bodyText]);
  in ''
    ${pad}${renderName nodeName} {
    ${childText}
    ${pad}}'';

  renderBind = level: key: rawBinding: let
    binding = normalize rawBinding;
  in
    renderNode level key ({props = normalizeProps (binding.props or {});} // (binding.content or {}));

  renderBinds = level: binds: ''
    ${indent level}binds {
    ${concatStringsSep "\n" (map (key: renderBind (level + 1) key binds.${key}) (attrNames binds))}
    ${indent level}}'';

  renderTop = name: value:
    if name == "outputs"
    then renderNamedAttrset 0 "output" value
    else if name == "workspaces"
    then renderNamedAttrset 0 "workspace" value
    else if name == "window-rules"
    then concatStringsSep "\n" (map (renderRule 0 "window-rule") value)
    else if name == "layer-rules"
    then concatStringsSep "\n" (map (renderRule 0 "layer-rule") value)
    else if name == "binds"
    then renderBinds 0 value
    else renderNode 0 name value;

  renderNiri = settings:
    concatStringsSep "\n\n" (map (name: renderTop name settings.${name}) (attrNames settings)) + "\n";
in {
  inherit renderNiri;
}
