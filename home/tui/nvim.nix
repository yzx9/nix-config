{
  self,
  vars,
  config,
  lib,
  ...
}:

let
  cfg = config.tui.editor.nvim;
  pkgs = self.packages.${vars.system};
  extend =
    pkg:
    pkg.extend {
      # Set 'vi' and 'vim' aliases to nixvim
      viAlias = true;
      vimAlias = true;
    };
in
lib.mkIf cfg.enable {
  home.packages =
    lib.optionals cfg.minimize [ (extend pkgs.nixvim-mini) ]
    ++ lib.optionals (!cfg.minimize) ([ (extend pkgs.nixvim) ] ++ pkgs.nixvim-formatters);

  # Set default editor
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.shellAliases = {
    v = "nvim";
  };
}
