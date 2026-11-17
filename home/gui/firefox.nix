{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.firefox;

  genAttrsWithFixValue = value: values: lib.genAttrs values (_: value);
in
{
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.enable
  # https://hugosum.com/blog/customizing-firefox-with-nix-and-home-manager#installing-firefox-with-home-manager
  programs.firefox = {
    enable = config.my.host.gui;

    # https://releases.mozilla.org/pub/firefox/releases/${version}/linux-x86_64/xpi/
    languagePacks = [
      "en-US"
      "zh-CN"
    ];

    # See: https://mozilla.github.io/policy-templates#enterprisepoliciesenabled
    # See also: about:policies#documentation
    policies = {
      AppAutoUpdate = false;
      DisableAppUpdate = true;
      ExtensionUpdate = false;
      PasswordManagerEnabled = false;
    };

    profiles.${config.my.user.name} = {
      isDefault = true;

      # https://searchfox.org/mozilla-release/source/modules/libpref/init/all.js
      # https://searchfox.org/mozilla-release/source/browser/app/profile/firefox.js
      settings = {
        # Privacy
        "app.update.auto" = false;
        "beacon.enabled" = false;
        "browser.formfill.enable" = false;
        "geo.enabled" = false;

        # Startup: restore previous windows and tabs
        "browser.startup.page" = 3;

        # UI
        "browser.aboutConfig.showWarning" = false;
        "browser.compactmode.show" = true;
        "browser.tabs.warnOnClose" = true;

        # Horizontal tabs: hide sidebar launcher
        # For vertical tabs, use "hide-sidebar" instead.
        "sidebar.visibility" = "hide-launcher";

        # Search suggestions
        "browser.search.suggest.enabled" = false;
        "browser.urlbar.suggest.searches" = false;

        # New tab: hide recommended and sponsored content
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.topsites.contile.enabled" = false;

        # AI chatbot
        "browser.ml.chat.enabled" = false;

        # Add-ons recommendations
        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;

      }
      // (lib.optionalAttrs pkgs.stdenvNoCC.hostPlatform.isLinux {
        # XDG Portal
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      });

      search = {
        force = true;
        default = "google";
        order = [
          "google"
          "ddg"
        ];
      };

      extensions = {
        # Whether to override all previous firefox settings.
        force = true;

        # TODO: Permission Allow Lists
        packages = with inputs.firefox-addons.packages."${config.my.system}"; [
          gopass-bridge
          privacy-badger
          readeck
          smartproxy
          vue-js-devtools
          zotero-connector
        ];
      };

      # Whether to force replace the existing containers configuration. This
      # is recommended since Firefox will replace the symlink on every launch,
      # but note that you’ll lose any existing configuration by enabling this.
      containersForce = true;
      # Attribute set of container configurations.
      # color: blue, turquoise, green, yellow, orange, red, pink, purple,
      #        toolbar
      # icon: briefcase, cart, circle, dollar, fence, fingerprint, gift,
      #       vacation, food, fruit, pet, tree, chill
      containers.lab = {
        id = 1;
        color = "blue";
        icon = "briefcase";
      };
    };
  };

  xdg = lib.mkIf (cfg.enable && pkgs.stdenvNoCC.hostPlatform.isLinux) {
    mimeApps = {
      enable = true;
      defaultApplications = genAttrsWithFixValue "firefox.desktop" [
        "application/pdf"
        "application/x-extension-htm"
        "application/x-extension-html"
        "application/x-extension-shtml"
        "application/x-extension-xht"
        "application/x-extension-xhtml"
        "application/xhtml+xml"
        "image/jpeg"
        "image/png"
        "text/html"
        "text/uri-list"
        "x-scheme-handler/chrome"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };

    configFile."mimeapps.list".force = true;
  };
}
