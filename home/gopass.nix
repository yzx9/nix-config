# Gopass password manager configuration
{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = lib.optionals config.purpose.daily [
    pkgs.gopass
  ];

  programs.firefox.nativeMessagingHosts = [
    pkgs.gopass-jsonapi
  ];
}
