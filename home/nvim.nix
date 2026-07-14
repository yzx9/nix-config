{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.yzx9.nixvim.extend {
      # Set 'vi' and 'vim' aliases to nixvim
      viAlias = true;
      vimAlias = true;

      proxy = config.my.proxy.http;
      lsp.enable = config.my.host.dev.enable; # disable lsp to minimize size by default
    })
  ];

  # Set default editor
  home.sessionVariables.EDITOR = "nvim";

  home.shellAliases.v = "nvim";
}
