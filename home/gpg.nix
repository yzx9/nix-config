{ pkgs, lib, ... }:

{
  programs.gpg = {
    enable = true;
    settings = {
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  home.packages = with pkgs; [
    pinentry_mac
  ];

  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    ".gnupg/gpg-agent.conf".text = ''
      pinentry-program ${lib.getBin pkgs.pinentry_mac}/bin/pinentry-mac
    '';
  };
}
