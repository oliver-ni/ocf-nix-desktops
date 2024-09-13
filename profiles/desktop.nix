{ pkgs, lib, inputs, ... }:

{
  ocf = {
    auth.enable = true;
    graphical.enable = true;
    tmpfsHome.enable = true;
  };

  boot.loader.systemd-boot.consoleMode = "max";

  environment.systemPackages = with pkgs; [
    # Languages
    (python312.withPackages (ps: [ ps.ocflib ]))
    poetry
    ruby
    elixir
    clojure
    ghc
    rustup
    clang
  ];

  services = {
    avahi.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa.enable = true;
    };
  };

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
}
