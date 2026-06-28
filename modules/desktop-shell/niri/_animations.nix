{screenshot-ui-open = {
    duration-ms = 200;
    curve = "ease-out-quad";
  };
  window-open = {
    duration-ms = 150;
    curve = "ease-out-expo";
  };
  window-close = {
    duration-ms = 150;
    curve = "ease-out-quad";
  };

  workspace-switch = {
    spring = _: {
      props = {
        damping-ratio = 0.65;
        stiffness = 1000;
        epsilon = 0.0001;
      };
    };
  };
  horizontal-view-movement = {
    spring = _: {
      props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
  };
  window-movement = {
    spring = _: {
      props = {
        damping-ratio = 0.8;
        stiffness = 1000;
        epsilon = 0.0001;
      };
    };
  };
  window-resize = {
    spring = _: {
      props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
  };
  config-notification-open-close = {
    spring = _: {
      props = {
        damping-ratio = 0.6;
        stiffness = 1000;
        epsilon = 0.001;
      };
    };
  };
  exit-confirmation-open-close = {
    spring = _: {
      props = {
        damping-ratio = 0.6;
        stiffness = 500;
        epsilon = 0.01;
      };
    };
  };
  overview-open-close = {
    spring = _: {
      props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
  };
  recent-windows-close = {
    spring = _: {
      props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.001;
      };
    };
  };
}
