# Gopass password manager configuration
{
  config,
  pkgs,
  lib,
  ...
}:

let
  enable = config.purpose.daily;
in
{
  home.packages = lib.optionals enable [ pkgs.gopass ];

  programs.firefox.nativeMessagingHosts = lib.optionals enable [ pkgs.gopass-jsonapi ];
}
