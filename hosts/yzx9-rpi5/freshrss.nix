{ config, pkgs, ... }:

let
  inherit (config) vars;
  baseUrl = "10.1.1.1";
  vhost = "freshrss";

  # Custom configuration for FreshRSS.
  # Only used before the first run, edit `/var/lib/freshrss/config.php after the install process is completed
  configCustom = pkgs.writeText "freshrss-config.custom.php" ''
    <?php

    return [
      'curl_options' => [
        # Options to use a proxy for retrieving feeds.
        CURLOPT_PROXYTYPE => CURLPROXY_HTTP,
        CURLOPT_PROXY => '127.0.0.1',
        CURLOPT_PROXYPORT => ${builtins.toString config.proxy.selfHost.httpProxyPublicPort},
      ]
    ];
  '';

  freshrssWithProxy = pkgs.freshrss.overrideAttrs (prev: {
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
    enable = true;

    package = freshrssWithProxy;

    virtualHost = vhost;
    baseUrl = baseUrl;

    defaultUser = vars.user.name;
    passwordFile = config.age.secrets."freshrss-pwd".path;
  };

  services.nginx.virtualHosts.${vhost} = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 4080;
      }
    ];
    # forceSSL = true;
  };

  #networking.firewall.allowedTCPPorts = [ port ];
}
