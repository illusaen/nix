{scheme}: {
  gaps = 12;
  struts = {
    left = 8;
    right = 8;
    top = 0;
    bottom = 0;
  };
  background-color = "transparent";
  focus-ring.off = _: {};
  border.off = _: {};
  shadow = {
    on = _: {};
    softness = 28;
    spread = 4;
    offset = _: {
      props = {
        x = 0;
        y = 8;
      };
    };
    color = "${scheme.base00}66";
  };
  center-focused-column = "on-overflow";
  default-column-width.proportion = 0.3;
  preset-column-widths = [
    {proportion = 0.3;}
    {proportion = 0.5;}
    {proportion = 0.7;}
  ];
  tab-indicator = {
    hide-when-single-tab = _: {};
    gap = 2;
    width = 4;
    active-gradient = _: {
      props = {
        from = scheme.base0C;
        to = scheme.base15;
      };
    };
    inactive-gradient = _: {
      props = {
        from = scheme.base02;
        to = scheme.base03;
        relative-to = "workspace-view";
      };
    };
    urgent-gradient = _: {
      props = {
        from = scheme.base08;
        to = scheme.base12;
      };
    };
  };
}
