{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.gpg = {
    enable = config.purpose.daily;

    settings = {
      keyid-format = "0xlong";
      with-fingerprint = true;
    };
  };

  services.gpg-agent = {
    enable = config.programs.gpg.enable;

    defaultCacheTtl = 60480000;
    maxCacheTtl = 60480000;

    enableSshSupport = true;
    defaultCacheTtlSsh = 60480000;
    maxCacheTtlSsh = 60480000;

    pinentry = lib.mkIf (config.purpose.gui && pkgs.stdenvNoCC.hostPlatform.isDarwin) {
      package = pkgs.pinentry_mac;
      program = "pinentry-mac";
    };
  };
}
