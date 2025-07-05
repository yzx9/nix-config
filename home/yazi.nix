{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.yazi = lib.mkMerge [
    {
      enable = true;
    }

    (lib.mkIf config.purpose.daily {
      plugins = {
        git = pkgs.yaziPlugins.git;
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
    })
  ];

  home.shellAliases.y = "yazi";
}
