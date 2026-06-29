{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
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

    };
  }

  (lib.mkIf (config.purpose.gui && pkgs.stdenvNoCC.hostPlatform.isDarwin) {
    services.gpg-agent.pinentry = {
      package = pkgs.pinentry_mac;
      program = "pinentry-mac";
    };

    # pinentry-mac will use the MacOS Keychain to store your passphrase indefinitely.
    # disabling this is recommended if you want to use gpg-agent with a password manager like gopass.
    targets.darwin.defaults."org.gpgtools.common".UseKeychain = false;
  })
]
