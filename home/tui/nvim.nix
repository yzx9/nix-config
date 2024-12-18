{
  self,
  config,
  lib,
  ...
}:

let
  pkgs = self.packages.${config.vars.system};
  extend =
    pkg:
    pkg.extend {
      # Set 'vi' and 'vim' aliases to nixvim
      viAlias = true;
      vimAlias = true;
    };
in
{
  home.packages =
    lib.optionals (!config.purpose.daily) [ (extend pkgs.nixvim-mini) ]
    ++ lib.optionals config.purpose.daily ([ (extend pkgs.nixvim) ] ++ pkgs.nixvim-formatters);

  # Set default editor
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.shellAliases = {
    v = "nvim";
  };
}
