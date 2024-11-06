{ config, lib, ... }:

{
  options.proxy.enable = lib.mkEnableOption "proxy";

  options.gui = {
    enable = lib.mkEnableOption "GUI apps";
  };

  options.tui = {
    editor.lsp.enable = lib.mkOption {
      description = "Enable LSP for the editor";
      type = lib.types.bool;
      default = true;
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
    rootless = lib.mkEnableOption "rootless" // {
      default = true;
    };
  };
}
