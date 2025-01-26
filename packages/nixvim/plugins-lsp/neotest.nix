{ config, lib, ... }:

lib.mkIf config.lsp.enable {
  plugins.neotest = {
    enable = true;
    adapters = {
      python.enable = true;
    };
  };
}
