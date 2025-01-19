{
  self,
  config,
  lib,
  ...
}:

{
  home.packages =
    let
      pkgs = self.packages.${config.vars.system};
      pkg = if config.purpose.daily then pkgs.nixvim else pkgs.nixvim-mini;
    in
    [
      (pkg.extend {
        # Set 'vi' and 'vim' aliases to nixvim
        viAlias = true;
        vimAlias = true;

        extraConfigLuaPre = lib.mkIf (!(builtins.isNull config.proxy.httpProxy)) ''
          vim.g.copilot_proxy = "${config.proxy.httpProxy}"
        '';
      })
    ];

  # Set default editor
  home.sessionVariables.EDITOR = "nvim";

  home.shellAliases.v = "nvim";
}
