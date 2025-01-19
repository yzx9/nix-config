{ self, config, ... }:

{
  home.packages = [
    (self.packages.${config.vars.system}.nixvim.extend {
      # Set 'vi' and 'vim' aliases to nixvim
      viAlias = true;
      vimAlias = true;

      lsp.enable = config.purpose.daily; # disable lsp to minimize size by default
      httpProxy = config.proxy.httpProxy;
    })
  ];

  # Set default editor
  home.sessionVariables.EDITOR = "nvim";

  home.shellAliases.v = "nvim";
}
