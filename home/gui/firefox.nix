{
  config,
  pkgs,
  lib,
  ...
}:

let
  genAttrsWithFixValue = value: values: lib.genAttrs values (_: value);
in
lib.mkIf config.purpose.gui {
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.enable
  # https://hugosum.com/blog/customizing-firefox-with-nix-and-home-manager#installing-firefox-with-home-manager
  programs.firefox = {
    enable = true;
    package = if pkgs.stdenvNoCC.hostPlatform.isDarwin then pkgs.firefox-bin else pkgs.firefox;

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
    };

    profiles.${config.vars.user.name} = {
      isDefault = true;

      # https://searchfox.org/mozilla-release/source/modules/libpref/init/all.js
      # https://searchfox.org/mozilla-release/source/browser/app/profile/firefox.js
      settings = {
        "app.update.auto" = false;
        "beacon.enabled" = false;
        "browser.aboutConfig.showWarning" = false;
        # Be kind to hard drive
        "browser.cache.disk.enable" = false;
        # Whether Firefox will show the Compact Mode UIDensity option.
        "browser.compactmode.show" = true;
        "browser.formfill.enable" = false;
        "browser.tabs.groups.enabled" = true;
        # Resume last session.
        "browser.startup.page" = 3;
        "browser.search.suggest.enabled" = false;
        "browser.search.suggest.enabled.private" = false;
        "browser.toolbars.bookmarks.visibility" = "newtab";
        "browser.toolbarbuttons.introduced.sidebar-button" = false;
        "browser.topsites.contile.enabled" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.suggest.searches" = false;
        # AI chat bot
        "browser.ml.chat.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.system.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "geo.enabled" = false;
        # If set to false, FxAccounts and Sync will be unavailable.
        "identity.fxaccounts.enabled" = true;
        "sidebar.visibility" = "hide-sidebar";
        "signon.rememberSignons" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;

        # Fully disable Pocket. See
        # https://www.reddit.com/r/linux/comments/zabm2a.
        "extensions.pocket.enabled" = false;
        "extensions.pocket.api" = "0.0.0.0";
        "extensions.pocket.loggedOutVariant" = "";
        "extensions.pocket.oAuthConsumerKey" = "";
        "extensions.pocket.onSaveRecs" = false;
        "extensions.pocket.onSaveRecs.locales" = "";
        "extensions.pocket.showHome" = false;
        "extensions.pocket.site" = "0.0.0.0";
        "browser.newtabpage.activity-stream.pocketCta" = "";
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" =
          false;
      };

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

        packages =
          (with pkgs.nur.repos.rycee.firefox-addons; [
            gopass-bridge
            # switchyomega
            privacy-badger
            vue-js-devtools
            zotero-connector
          ])
          ++ lib.singleton (
            pkgs.fetchFirefoxAddon {
              name = "zeroomega";
              url = "https://addons.mozilla.org/firefox/downloads/file/4442919/zeroomega-3.3.23.xpi";
              hash = "sha256-DpYUoJmVVgVEUT+lm3ppYAfMdl7qCCeZ35QFBGYuNPs=";
            }
          );
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

  xdg = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isLinux {
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
