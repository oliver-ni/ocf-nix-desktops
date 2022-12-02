{ config, pkgs, ... }:

{
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_6_0;

  # Timezones and Locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # TODO: if this user is accessed, send audit notification to relevant staff via forcecommand
  # break-glass emergency root user
  users.users.ocfemergency = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiiq/rSfG+bKmqKZfCSl1z2r7rc3Wt/Paya/JYmjdSO strudel@nikhiljha.com"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrkdSorbUk6DtvdsKtS50CS7icElFQIC8rgjI4aOXCzcazTWRJB82x1dwDNIihxZB9KRQJ2939mUO3UhDfrB1JFlFvDtbH3FsZBxjn7eHZg3Z4wE8UjRwf1j/DBACoO3vBjRkIWE4r1auTMvFbA+jMYcfEv2qWX1xyGj6e2NmhSftfMQeEfucgtkxeq/sPMLXNAL53z9YvI0g7JLGTM0a59h6REccWwifgnSGYQRbKeO13+RCvQWODufjJ6xq4A6lruh5Ajh87MYFzjkHcEqw2EF6c9eT9bX51yOTPBoRNvA+RU0ZjKYtenD2WRU6Q3Px3uKIuFIi8lCuie7flsWsr fydai@ocf.berkeley.edu"
    ];
  };
  
  security.sudo.extraRules = [
    { 
      users = [ "ocfemergency" ];
      commands = [
         {
           command = "ALL" ;
           options= [ "NOPASSWD" ];
         }
      ];
    }
  ];

  # Base set of packages to install...
  environment.systemPackages = with pkgs; [
    # System Utilities
    util-linux
    iproute2
    ethtool

    # Helpful Tools
    vim
    wget
    git
  ];

  # TODO: Replace me with teleport SSH!
  services.openssh.enable = true;

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # TODO: This won't work for fallingrocks...
  networking.defaultGateway = "169.229.226.1";
  networking.defaultGateway6 = "2607:f140:8801::1";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.useDHCP = false;

  # THIS SETTING DOES NOT DO WHAT YOU THINK IT DOES
  # DO NOT MODIFY IT UNTIL YOU HAVE READ AND UNDERSTOOD
  # https://search.nixos.org/options?show=system.stateVersion
  system.stateVersion = "22.11";
}
