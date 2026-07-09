{
  lib,
  monitors,
}: let
  secondaryMonitor =
    if monitors.secondary != null
    then monitors.secondary
    else monitors.main;
in {
  "music" =
    {
      open-on-output = secondaryMonitor;
      layout = {
        default-column-width.proportion = 0.8;
        preset-column-widths = [
          {proportion = 0.8;}
          {proportion = 0.666667;}
        ];
      };
    }
    // lib.optionalAttrs (monitors.secondary == null) {
      layout.always-center-single-column = _: {};
    };
  "chat" = {
    open-on-output = monitors.main;
  };
  "code" = {
    open-on-output = monitors.main;
  };
  "gaming" = {
    open-on-output = monitors.main;
    layout.always-center-single-column = _: {};
  };
  "__ndrop" = {
    open-on-output = monitors.main;
  };
}
