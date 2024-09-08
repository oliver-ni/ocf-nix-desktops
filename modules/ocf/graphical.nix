{ lib, config, pkgs, ... }:

let
  cfg = config.ocf.graphical;

  # Default openssh doesn't include GSSAPI support, so we need to override sshfs
  # to use the openssh_gssapi package instead. This is annoying because the
  # sshfs package's openssh argument is nested in another layer of callPackage,
  # so we override callPackage instead to override openssh.
  sshfs = pkgs.sshfs.override {
    callPackage = fn: args: (pkgs.callPackage fn args).override {
      openssh = pkgs.openssh_gssapi;
    };
  };
in
{
  options.ocf.graphical = {
    enable = lib.mkEnableOption "Enable desktop environment configuration";
  };

  config = lib.mkIf cfg.enable {
    security.pam = {
      # Mount ~/remote
      services.login.pamMount = true;
      services.login.rules.session.mount.order = config.security.pam.services.login.rules.session.krb5.order + 50;
      mount.extraVolumes = [ ''<volume fstype="fuse" path="${sshfs}/bin/sshfs#%(USER)@tsunami:" mountpoint="~/remote/" options="follow_symlinks,UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no" pgrp="ocf" />'' ];

      # Create home directories
      services.login.makeHomeDir = true;
      services.sshd.makeHomeDir = true;
      makeHomeDir.skelDirectory = "/etc/skel";
    };

    boot = {
      loader.timeout = 0;
      initrd.systemd.enable = true;
    };

    environment.etc = {
      skel.source = ./graphical/skel;
      ocf-assets.source = ./graphical/assets;
    };

    programs.steam.enable = true;

    programs.firefox = {
      enable = true;
      policies = {
        Homepage.URL = "https://www.ocf.berkeley.edu/about/lab/open-source";
        PromptForDownloadLocation = true;

        FirefoxHome = {
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
          Locked = true;
        };

        DisableFirefoxAccounts = true;
        DisableFormHistory = true;

        SanitizeOnShutdown = {
          Cache = true;
          Cookies = true;
          Downloads = true;
          FormData = true;
          History = true;
          Sessions = true;
          SiteSettings = true;
          OfflineApps = true;
        };

        DontCheckDefaultBrowser = true;
        DisableBuiltinPDFViewer = true;
        OverrideFirstRunPage = "https://www.ocf.berkeley.edu/about/lab/open-source";

        Authentication.SPNEGO = [ "auth.ocf.berkeley.edu" "idm.ocf.berkeley.edu" ];

        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
        };
      };
    };

    programs.chromium = {
      enable = true;
      extraOpts = {
        # https://chromeenterprise.google/policies/

        # Set OCF homepage
        HomepageLocation = "https://www.ocf.berkeley.edu/about/lab/open-source";
        HomepageIsNewTabPage = false;
        ShowHomeButton = true;
        RestoreOnStartup = 4;
        RestoreOnStartupURLs = [
          "https://www.ocf.berkeley.edu/about/lab/open-source"
        ];

        # Do not store browser history etc.
        ForceEphemeralProfiles = true;
        SavingBrowserHistoryDisabled = true;
        PasswordManagerEnabled = false;
        IncognitoModeAvailability = 0;

        # Avoid reporting data to and integrating with Google
        BrowserSignin = 0;
        MetricsReportingEnabled = false;
        CloudPrintProxyEnabled = false;
        CloudPrintSubmitEnabled = false;
        HideWebStoreIcon = true;
        SyncDisabled = true;
        TranslateEnabled = true;
        DefaultBrowserSettingEnabled = false;

        # Allow SPNEGO for Keycloak SSO
        AuthServerAllowlist = "auth.ocf.berkeley.edu,idm.ocf.berkeley.edu";
        AuthNegotiateDelegateAllowlist = "auth.ocf.berkeley.edu,idm.ocf.berkeley.edu";

        # Printing from Chrome's PDF viewer often results in cut-off pages
        DisablePrintPreview = true;
        AlwaysOpenPdfExternally = true;

        # Disable Privacy Sandbox popup
        PrivacySandboxAdMeasurementEnabled = false;
        PrivacySandboxPromptEnabled = false;
        PrivacySandboxAdTopicsEnabled = false;
        PrivacySandboxSiteEnabledAdsEnabled = false;

        # uBlock Origin
        ExtensionInstallForcelist = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ];
      };
    };

    environment.systemPackages = with pkgs; [
      pkgs.ocf.plasma-applet-commandoutput
      (pkgs.ocf.catppuccin-sddm.override {
        themeConfig.General = {
          FontSize = 12;
          Background = "/etc/ocf-assets/images/login.png";
          Logo = "/etc/ocf-assets/images/penguin.svg";
          CustomBackground = true;
        };
      })
      google-chrome
      firefox
      libreoffice
      vscode-fhs
      kitty

      # temporary ATDP programs
      filezilla
      sublime
    ];

    fonts.packages = with pkgs; [ meslo-lgs-nf noto-fonts noto-fonts-cjk noto-fonts-extra ];

    services.xserver = {
      enable = true;

      # KDE is our primary DE, but have others available
      desktopManager.plasma6.enable = true;
      desktopManager.gnome.enable = true;
      desktopManager.xfce.enable = true;

      displayManager = {
        defaultSession = "plasma";

        sddm = {
          enable = true;
          # theme = "catppuccin-latte";
          wayland.enable = true;
          settings.Users = {
            RememberLastUser = false;
            RememberLastSession = false;
          };
        };
      };

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    # KDE 6.0.3 has a bug that breaks logging out within the first 60 seconds.
    # This is caused by the DrKonqi service's ExecStartPre command, which sleeps
    # for 60 seconds to let the system settle before monitoring coredumps. We
    # don't need this wait, so we remove the ExecStartPre entry.
    systemd.user.services.drkonqi-coredump-pickup.unitConfig.ExecStartPre = lib.mkForce [ ];

    systemd.user.services.wayout = {
      description = "Automatic idle logout manager";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.ocf.wayout}/bin/wayout";
        Type = "simple";
        Restart = "on-failure";
      };
    };

    systemd.user.services.desktoprc = {
      description = "Source custom rc shared across desktops";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      script = ''
        [ -f ~/remote/.desktoprc ] && . ~/remote/.desktoprc
      '';
    };

    # Conflict override since multiple DEs set this option
    programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
  };
}
