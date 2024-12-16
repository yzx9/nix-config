{ config, lib, ... }:

let
  mkEnabledOption = name: (lib.mkEnableOption name) // { default = true; };
in
{
  options.purpose = {
    daily = lib.mkEnableOption "for daily use";
    gui = lib.mkEnableOption "for GUI use";
  };

  options.proxy = {
    enable = lib.mkEnableOption "proxy";
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
