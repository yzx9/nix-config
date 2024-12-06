{
  config,
  pkgs,
  lib,
  ...
}:

let
  pinentry = config.purpose.gui;
in
{
  programs.gpg = {
    enable = true;
    settings = {
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  home.packages = lib.optionals (pinentry && pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.pinentry_mac ];

  # services.gpg-agent is broken in darwin, see: https://github.com/nix-community/home-manager/issues/3864
  home.file.".gnupg/gpg-agent.conf".text =
    ''
      default-cache-ttl 60480000
      max-cache-ttl 60480000

      enable-ssh-support
      default-cache-ttl-ssh 60480000
      max-cache-ttl-ssh 60480000
    ''
    + lib.optionalString (pinentry && pkgs.stdenv.hostPlatform.isDarwin) ''
      pinentry-program ${lib.getBin pkgs.pinentry_mac}/bin/pinentry-mac
    '';
}
