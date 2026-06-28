{cursor}: {
  cursor = {
    xcursor-theme = "${cursor.name}";
    xcursor-size = cursor.size;
  };

  input = {
    mouse = {
      middle-emulation = _: {};
      accel-speed = 1;
      scroll-button = 274;
      scroll-method = "on-button-down";
      scroll-factor = 1.1;
    };
    warp-mouse-to-focus = _: {};
  };
}
