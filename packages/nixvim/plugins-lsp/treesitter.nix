{ config, lib, ... }:

lib.mkIf config.lsp.enable {
  plugins.treesitter = {
    enable = true;

    settings = {
      highlight = {
        enable = true;
        # TODO
        additional_vim_regex_highlighting = false;
      };
    };
  };
}
