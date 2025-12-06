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
      };

      lazyLoad.settings = {
        cmd = "Copilot";
        event = "InsertEnter";
      };
    };

    # Lua plugin to turn github copilot into a cmp source
    # homepage: https://github.com/zbirenbaum/copilot-cmp/
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/copilot-cmp.html
    copilot-cmp.enable = true;

    cmp.settings.sources = [ { name = "copilot"; } ];
  };

  extraConfigLuaPre = lib.optionalString (config.httpProxy != null) ''
    vim.g.copilot_proxy = "${config.httpProxy}"
  '';
}
