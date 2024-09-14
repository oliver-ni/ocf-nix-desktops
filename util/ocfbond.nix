# OCF Bond Generator
interfaces: {
  inherit interfaces;
  driverOptions = {
    mode = "802.3ad";
    miimon = "100";
  };
}

