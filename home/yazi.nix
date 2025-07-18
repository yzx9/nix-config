{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  programs.yazi = lib.mkMerge [
    {
      enable = true;
      shellWrapperName = "y";
    }

    (lib.mkIf config.purpose.daily {
      theme.flavor.dark = "mocha";

      flavors.mocha = inputs.self.packages.${config.vars.system}.catppuccin-yazi-flavor.override {
        flavor = "mocha";
        color = "blue";
      };

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
}
