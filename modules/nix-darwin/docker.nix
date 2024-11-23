{ config, lib, ... }:

let
  cfg = config.docker;
in
{
  config = lib.mkIf cfg.enable {
    # nixpkgs docker is breaked, see: https://github.com/LnL7/nix-darwin/issues/112
    homebrew.casks = [ "docker" ];
  };
}
