{
  config,
  pkgs,
  vars,
  ...
}:

let
  url = "10.3.1.125";
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
    package = pkgs.freshrss.overrideAttrs (old: {
      overrideConfigCustom = pkgs.writeText "config.custom.php" ''
        <?php
        return array(
          'curl_options' => array(
            # Options to use a proxy for retrieving feeds.
            CURLOPT_PROXY => 'http://127.0.0.1:12345',
          ),
        );
      '';

      installPhase = ''
        ${old.installPhase}
        cp $overrideConfigCustom $out/config.custom.php
      '';
    });
    baseUrl = "http://${url}";
    virtualHost = vhost;

    defaultUser = vars.user.name;
    passwordFile = config.age.secrets."rss-pwd".path;
  };

  # services.nginx.virtualHosts.${vhost}.forceSSL = true;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
