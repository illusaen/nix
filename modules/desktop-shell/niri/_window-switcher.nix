{highlightColor}: {
  previews = {
    max-height = 1080;
    max-scale = 0.75;
  };
  highlight = {
    active-color = "${highlightColor}ff";
    padding = 30;
    corner-radius = 12;
  };
  binds = {
    "Alt+Tab".next-window = _: {};
    "Alt+Shift+Tab".previous-window = {};
    "Alt+grave".next-window = _: {props.filter = "app-id";};
    "Alt+Shift+grave".previous-window = _: {props.filter = "app-id";};
  };
}
