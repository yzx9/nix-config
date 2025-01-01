{
  config,
  pkgs,
  ...
}:

let
  inherit (config) vars;
  baseUrl = "10.1.1.1";
  vhost = "freshrss";
in
{
  age.secrets."rss-pwd" = {
    file = ../../secrets/rss-pwd.age;
    owner = "freshrss";
    group = "freshrss";
  };

  services.freshrss = {
    enable = true;
    package = pkgs.freshrss.overrideAttrs (previousAttrs: {
      overrideConfigCustom = pkgs.writeText "config.custom.php" ''
        <?php

        return [
          'curl_options' => [
            # Options to use a proxy for retrieving feeds.
            CURLOPT_PROXYTYPE => CURLPROXY_HTTP,
            CURLOPT_PROXY => '127.0.0.1',
            CURLOPT_PROXYPORT => 12345,
          ]
        ];
      '';

      postInstall = (previousAttrs.postInstall or "") + ''
        cp $overrideConfigCustom $out/data/config.custom.php
      '';
    });
    virtualHost = vhost;
    baseUrl = baseUrl;

    defaultUser = vars.user.name;
    passwordFile = config.age.secrets."rss-pwd".path;
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
