{ self, config, ... }:

{
  home.packages = [
    (self.packages.${config.vars.system}.nixvim.extend {
      # Set 'vi' and 'vim' aliases to nixvim
      viAlias = true;
      vimAlias = true;

      httpProxy = config.proxy.httpProxy;
      lsp.enable = config.purpose.daily; # disable lsp to minimize size by default
      yazi.package = null; # use global yazi package which includes plugins
    })
  ];

  # Set default editor
  home.sessionVariables.EDITOR = "nvim";

  home.shellAliases.v = "nvim";
}
