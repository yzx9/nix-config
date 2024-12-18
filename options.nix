{ config, lib, ... }:

let
  mkEnabledOption = name: (lib.mkEnableOption name) // { default = true; };
in
{
  options.vars = {
    type = lib.mkOption {
      type = lib.types.enum [
        "nixos"
        "nix-darwin"
        "home-manager"
      ];
      description = "The type of configuration to generate";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      description = "The hostname of the machine";
    };

    system = lib.mkOption {
      type = lib.types.enum [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      description = "The system of the machine";
    };

    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "The name of the user";
      };

      git = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "The name of the user";
        };

        email = lib.mkOption {
          type = lib.types.str;
          description = "The email of the user";
        };
      };
    };
  };

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
