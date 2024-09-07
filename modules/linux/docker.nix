{ config, lib, ... }:

let
  cfg = config.docker;
in
{
  config.virtualisation.docker = lib.mkIf cfg.enable {
    enable = true;

    # non-rootless was not implemented yet
    rootless = lib.mkIf cfg.rootless {
      enable = true;
      setSocketVariable = true;
    };
  };
}
