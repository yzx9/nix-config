{ pkgs, lib, ... }:

{
  programs.gpg = {
    enable = true;
    settings = {
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  home.packages = lib.optionals pkgs.stdenv.isDarwin (
    with pkgs; [
      pinentry_mac
    ]
  );

  home.file.".gnupg/gpg-agent.conf".text = ''
    default-cache-ttl 60480000
    max-cache-ttl 60480000

    enable-ssh-support
    default-cache-ttl-ssh 60480000
    max-cache-ttl-ssh 60480000
  '' + lib.optionalString pkgs.stdenv.isDarwin ''
    pinentry-program ${lib.getBin pkgs.pinentry_mac}/bin/pinentry-mac
  '';
}

