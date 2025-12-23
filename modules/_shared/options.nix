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
    daily = lib.mkEnableOption "for daily use, including coding, will install many applications";
    gui = lib.mkEnableOption "for GUI use, will install GUI-specific applications";

    dev = {
      enable = lib.mkEnableOption "for development, will install development-specific applications";

      nix.enable = (lib.mkEnableOption "for Nix development, will install Nix-specific applications") // {
        default = config.purpose.dev.enable;
      };

      ops.enable = (lib.mkEnableOption "for Ops, will install Ops-specific applications") // {
        default = config.purpose.dev.enable;
      };
    };
  };

  options.proxy = {
    selfHost = {
      enable = lib.mkEnableOption "self-hosted proxy";
      public = lib.mkEnableOption "public & auto switching http proxy";

      socksProxyPort = lib.mkOption {
        type = lib.types.int;
        default = 10086;
      };

      httpProxyPort = lib.mkOption {
        type = lib.types.int;
        default = 10087;
      };

      httpProxyPublicPort = lib.mkOption {
        type = lib.types.int;
        default = 12345;
      };
    };

    socksProxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if config.proxy.selfHost.enable then
          "127.0.0.1:${builtins.toString config.proxy.selfHost.socksProxyPort}"
        else
          null;
    };

    httpProxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if config.proxy.selfHost.enable then
          "127.0.0.1:${builtins.toString config.proxy.selfHost.httpProxyPort}"
        else
          null;
    };

    httpPublicProxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if config.proxy.selfHost.enable then
          "127.0.0.1:${builtins.toString config.proxy.selfHost.httpProxyPublicPort}"
        else
          null;
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
