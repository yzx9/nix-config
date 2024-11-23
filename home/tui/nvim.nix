{
  self,
  vars,
  config,
  lib,
  ...
}:

let
  cfg = config.tui.editor.nvim;
in
lib.mkIf cfg.enable {
  home.packages = [
    (
      let
        pkg =
          if cfg.minimize then
            self.packages.${vars.system}.nixvim
          else
            self.packages.${vars.system}.nixvim-mini;
      in
      pkg.extend {
        # Set 'vi' and 'vim' aliases to nixvim
        viAlias = true;
        vimAlias = true;
      }
    )
  ];

  # Set default editor
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.shellAliases = {
    v = "nvim";
  };
}
