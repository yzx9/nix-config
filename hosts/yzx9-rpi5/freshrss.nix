{ config, pkgs, ... }:

let
  inherit (config) vars;

  virtualHost = "freshrss";

  # Custom configuration for FreshRSS.
  # Only used before the first run, edit `/var/lib/freshrss/config.php after the install process is completed
  configCustom = pkgs.writeText "freshrss-config.custom.php" ''
    <?php

    return [
      'curl_options' => [
        # Options to use a proxy for retrieving feeds.
        CURLOPT_PROXYTYPE => CURLPROXY_HTTP,
        CURLOPT_PROXY => '127.0.0.1',
        CURLOPT_PROXYPORT => ${toString config.proxy.selfHost.httpPublicPort},
      ]
    ];
  '';

  # Override FreshRSS package to include custom configuration file.
  package = pkgs.freshrss.overrideAttrs (prev: {
    postInstall = (prev.postInstall or "") + ''
      cp ${configCustom} $out/config.custom.php
    '';
  });
in
{
  age.secrets."freshrss-pwd" = {
    file = ../../secrets/freshrss-pwd.age;
    owner = config.services.freshrss.user;
    group = config.users.users.${config.services.freshrss.user}.group;
  };

  services.freshrss = {
    inherit package virtualHost;

    enable = true;
    baseUrl = "127.0.0.1";
    defaultUser = vars.user.name;
    passwordFile = config.age.secrets."freshrss-pwd".path;

    extensions = [
      (pkgs.freshrss-extensions.buildFreshRssExtension {
        FreshRssExtUniqueId = "readeck-button";
        pname = "xExtension-readeck-button";
        version = "0.14";
        src = pkgs.fetchFromGitHub {
          owner = "Joedmin";
          repo = "xExtension-readeck-button";
          tag = "0.14";
          hash = "sha256-f+PwifmLXzVOCyVivgP/E8Rmjv03TES3LX2GO6n8uM0=";
        };
      })
    ];
  };

  services.nginx.virtualHosts.${virtualHost} = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 4080;
      }
    ];
    # forceSSL = true;
  };

  #networking.firewall.allowedTCPPorts = [ port ];

  # `passwordFile` is consumed by the `freshrss-config` oneshot service.
  systemd.services.freshrss-config.restartTriggers = [
    "${config.age.secrets."freshrss-pwd".file}"
  ];
}
