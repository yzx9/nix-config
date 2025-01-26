{ config, pkgs, ... }:

let
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "8ed253716c60f3279518ce34c74ca053530039d8";
    hash = "sha256-xY2yVCLLcXRyFfnmyP6h5Fw+4kwOZhEOCWVZrRwXnTA=";
  };

  yaziWithPlugins = pkgs.yazi.override {
    plugins = {
      "git.yazi" = "${yazi-plugins}/git.yazi";
    };

    initLua = pkgs.writeText "yazi-initlua" ''
      require("git"):setup()
    '';

    settings."yazi.toml" = {
      plugin.prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }

        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
    };
  };
in
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    plugins = {
      git = "${yazi-plugins}/git.yazi";
    };

    initLua = ''
      require("git"):setup()
    '';

    settings = {
      plugin.prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }

        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
    };
  };
}
