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
  programs.firefox = {
    enable = true;

    languagePacks = [
      "en-US"
      "zh-CN"
    ];

    profiles.yzx9 = {
      id = 0;
      name = "yzx9";
      isDefault = true;

      # https://searchfox.org/mozilla-release/source/modules/libpref/init/all.js
      # https://searchfox.org/mozilla-release/source/browser/app/profile/firefox.js
      settings = {
        "app.update.auto" = false;

        "browser.aboutConfig.showWarning" = false;
        # Whether Firefox will show the Compact Mode UIDensity option.
        "browser.compactmode.show" = true;
        "browser.cache.disk.enable" = false; # Be kind to hard drive
        "browser.topsites.contile.enabled" = false;
        "browser.formfill.enable" = false;

        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.search.suggest.enabled" = false;
        "browser.search.suggest.enabled.private" = false;

        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.system.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.pocket.enabled" = false;

        "signon.rememberSignons" = true;

        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };

      search = {
        force = true;
        default = "Google";
        order = [
          "Google"
          "DuckDuckGo"
        ];
      };

      extensions = {
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          gopass-bridge
          # switchyomega
          vue-js-devtools
          zotero-connector
        ];
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
