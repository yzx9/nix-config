{ config, lib, ... }:

let
  mkEnabledOption = name: (lib.mkEnableOption name) // { enable = true; };
in
{
  options.proxy.enable = lib.mkEnableOption "proxy";

  options.gui = {
    enable = lib.mkEnableOption "GUI apps";
  };

  options.tui = {
    editor.nvim = {
      enable = mkEnabledOption "neovim";
      minimize = lib.mkEnableOption "minimize, without LSP";
    };
  };

  options.nvidia = {
    enable = lib.mkEnableOption "NVIDIA driver";
    package = lib.mkOption {
      description = "The NVIDIA driver package to use";
      type = lib.types.package;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  options.docker = {
    enable = lib.mkEnableOption "docker";
    rootless = mkEnabledOption "rootless";
  };
}
