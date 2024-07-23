{ config, lib, ... }:

let
  cfg = config.gui;
in
{
  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      font = {
        name = "FiraCode Nerd Font";
      };
      #settings = {
      #  shell = "zsh --login -c nu --login --interactive"; # Spawn a nushell in login mode via default shell
      #};
      extraConfig = ''
        background_opacity 0.75
      '';
    };
  };
}
