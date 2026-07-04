{ config, pkgs, ... }:

{
  # PinePhone: https://nixos.wiki/wiki/PinePhone
  services.xserver = {
    enable = true;
    desktopManager.phosh = {
      enable = true;
      user = config.vars.user.name;
      group = "users";
      # for better compatibility with x11 applications
      phocConfig.xwayland = "immediate";
    };
  };

  environment.systemPackages = with pkgs; [
    phosh-mobile-settings
  ];
}
