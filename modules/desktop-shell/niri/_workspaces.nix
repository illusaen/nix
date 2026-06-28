{monitors}: {
  "music" = {
            open-on-output = monitors.secondary;
            layout = {
              default-column-width.proportion = 0.8;
              preset-column-widths = [
                {proportion = 0.8;}
                {proportion = 0.666667;}
              ];
            };
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
          "__ndrop_foot" = {
            open-on-output = monitors.main;
          };
}
