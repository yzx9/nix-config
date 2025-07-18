{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.nixvim.extend {
      # Set 'vi' and 'vim' aliases to nixvim
      viAlias = true;
      vimAlias = true;

      httpProxy = config.proxy.httpProxy;
      lsp.enable = config.purpose.dev.enable; # disable lsp to minimize size by default
    })
  ];

  # Set default editor
  home.sessionVariables.EDITOR = "nvim";

  home.shellAliases.v = "nvim";
}
