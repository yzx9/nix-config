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

      extraConfigLuaPre = lib.mkIf config.proxy.enable ''
        vim.g.copilot_proxy = "http://127.0.0.1:10087"
      '';
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
