# Copilot related plugins and configuration for nixvim
{ config, lib, ... }:

{
  plugins = {
    # Fully featured & enhanced replacement for copilot.vim complete with API
    # for interacting with Github Copilot
    #
    # NOTE: Once copilot is running, run :Copilot auth to start the authentication
    # process
    #
    # homepage: https://github.com/zbirenbaum/copilot.lua
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/copilot-lua/index.html
    copilot-lua = {
      enable = true;

      settings = {
        suggestion.enabled = false;
        panel.enabled = false;
        filetypes = {
          markdown = true;
          help = true;
        };
      };

      lazyLoad.settings = {
        cmd = "Copilot";
        event = "InsertEnter";
      };
    };

    # Configurable GitHub Copilot suggestions source for blink.cmp
    # homepage: https://github.com/fang2hou/blink-copilot
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/blink-copilot/index.html
    blink-copilot.enable = true;

    blink-cmp.settings.sources = {
      default = [ "copilot" ];
      providers.copilot = {
        name = "copilot";
        module = "blink-copilot";
        score_offset = 100;
        async = true;
      };
    };
  };

  extraConfigLuaPre = lib.optionalString (config.httpProxy != null) ''
    vim.g.copilot_proxy = "${config.httpProxy}"
  '';
}
