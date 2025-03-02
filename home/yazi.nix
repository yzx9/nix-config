{ pkgs, ... }:

let
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "beb586aed0d41e6fdec5bba7816337fdad905a33";
    hash = "sha256-enIt79UvQnKJalBtzSEdUkjNHjNJuKUWC4L6QFb3Ou4=";
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

  home.shellAliases.y = "yazi";
}
