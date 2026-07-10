{
  lib,
  monitors,
}:
{
  "${monitors.main}" = {
    scale = 1;
    focus-at-startup = _: {};
    transform = "normal";
    position = _: {
      props = {
        x = 0;
        y = 0;
      };
    };
    mode = "5120x2160@100.035";
  };
}
// lib.optionalAttrs (monitors.secondary != null) {
  "${monitors.secondary}" = {
    scale = 1;
    transform = "270";
    position = _: {
      props = {
        x = 5120;
        y = 120;
      };
    };
    hot-corners.off = _: {};
  };
}
