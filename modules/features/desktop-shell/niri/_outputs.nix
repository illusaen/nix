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
    transform = "90";
    position = _: {
      props = {
        x = 1080;
        y = 120;
      };
    };
  };
}
