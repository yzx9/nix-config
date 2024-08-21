{ config, lib, ... }:

{
  options.gui = {
    enable = lib.mkEnableOption "GUI apps";
  };

  options.nvidia = {
    enable = lib.mkEnableOption "NVIDIA driver";
    package = lib.mkOption {
      description = "The NVIDIA driver package to use";
      type = lib.types.package;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
