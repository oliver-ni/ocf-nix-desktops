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

  # TODO: If this user is accessed, send audit notification to staff via a forcecommand.
  # A user to use iff we can no longer access nodes via teleport.
  users.users.ocfemergency = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # This should contain the public keys of 1) the current Site Managers 2) a USB TPM locked in a box in the
    # server room. We haven't gotten to setting up the second thing yet, but do this eventually(TM).
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiiq/rSfG+bKmqKZfCSl1z2r7rc3Wt/Paya/JYmjdSO strudel@nikhiljha.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2yyisYL1t5u4f0FPBFKs0jAr4MWZphCb8beBvu7xSw etw@ocf.berkeley.edu"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVE2dTNVA/m2VeEq18HTWOhDvFYr33O0OW0ivBKEFJc rjz@ocf.berkeley.edu"
    ];
  };

  # Make ocfemergency effectively root via sudo rules.
  security.sudo.extraRules = [
    {
      users = [ "ocfemergency" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
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

  # This can run concurrently with Teleport SSH. We use this just in case!
  services.openssh.enable = true;

  # Teleport
  services.teleport = {
    enable = true;
    settings = {
      version = "v2";
      teleport = {
        nodename = config.networking.hostName;
        # This file needs to be manually placed.
        # Maybe it can be automated once ~njha builds the cool TPM-based trust thing.
        # Then as long as hardware has ever been provisioned in the past, it can grab its own token.
        auth_token = "/var/lib/ocfteleport/authtoken";
        auth_servers = [ "tele.ocf.io:443" ];
      };
      ssh_service.enabled = true;
      auth_service.enabled = false;
      proxy_service.enabled = false;
      app_service.enabled = false;
      kubernetes_service.enabled = false;
      discovery_service.enabled = false;
      db_service.enabled = false;
      windows_desktop_service.enabled = false;
    };
  };

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # TODO: This won't work for fallingrocks...
  networking.defaultGateway = "169.229.226.1";
  networking.defaultGateway6 = "2607:f140:8801::1";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.useDHCP = false;

  # TODO: Move this to another file.
  # This is the OCF Root certificate, stored in a safe in the server
  # room. If someone has access to the server room it's game over
  # anyway so this is Secure (TM).
  security.pki.certificates = [''
      -----BEGIN CERTIFICATE-----
    MIIC7jCCAk+gAwIBAgIUZPQZpVG1GfVIKkcvKb5vwky5RTAwCgYIKoZIzj0EAwQw
    gY8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMREwDwYDVQQHEwhC
    ZXJrZWxleTEgMB4GA1UEChMXT3BlbiBDb21wdXRpbmcgRmFjaWxpdHkxDDAKBgNV
    BAsTA0FsbDEoMCYGA1UEAxMfT3BlbiBDb21wdXRpbmcgRmFjaWxpdHkgUm9vdCBY
    MTAgFw0yMzAxMTYyMzM5MDBaGA8yMTIzMDExNjIzMzkwMFowgY8xCzAJBgNVBAYT
    AlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMREwDwYDVQQHEwhCZXJrZWxleTEgMB4G
    A1UEChMXT3BlbiBDb21wdXRpbmcgRmFjaWxpdHkxDDAKBgNVBAsTA0FsbDEoMCYG
    A1UEAxMfT3BlbiBDb21wdXRpbmcgRmFjaWxpdHkgUm9vdCBYMTCBmzAQBgcqhkjO
    PQIBBgUrgQQAIwOBhgAEAaXbYJW1MmFY27rALUopMUWDNC4DS+A4trLyTOqf8M+x
    OrIDDkaEZHjhD5ofAcsyCKQf4tMNGqsj4RKAYhOxJLLDAHJLcpV63S+EojFkUJpr
    PtH81lf9toed/yi16f+V159qQ+PF+cGSXkHSyzUHPcqhuVrbuH37/AJNohgDPGmN
    rKWDo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
    FgQUYk/x6J54THpb1Xv9lNNqZWvbEtMwCgYIKoZIzj0EAwQDgYwAMIGIAkIBzWa7
    +3IgvnGLPv5UaU1tQVOGfAfvW3LYtZSDZ543bAIFVNLxpdhozZAeAfjBuPzSY/yh
    T1O56toa7dMv4tILfGsCQgGSQ3VEVnuqwUTGnchcZYsHZtsRSQ/AglekXrphZCxa
    xqg2jrBElQrI7xM3NcqlerzdvSzMgVJA3XyqXQJ7uAC9ag==
    -----END CERTIFICATE-----
  ''];

  # THIS SETTING DOES NOT DO WHAT YOU THINK IT DOES
  # DO NOT MODIFY IT UNTIL YOU HAVE READ AND UNDERSTOOD
  # https://search.nixos.org/options?show=system.stateVersion
  system.stateVersion = "22.11";
}
