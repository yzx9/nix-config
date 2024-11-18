{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kanboard;

  toStringAttrs = attrs: lib.attrsets.mapAttrs (k: v: toString v) attrs;
in
{
  meta.maintainers = with lib.maintainers; [ yzx9 ];

  options.services.kanboard = with lib; {
    enable = mkEnableOption "Kanboard";

    package = mkPackageOption pkgs "kanboard" { };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/kanboard";
      description = "Default data folder for Kanboard.";
      example = "/mnt/kanboard";
    };

    user = mkOption {
      type = types.str;
      default = "kanboard";
      description = "User under which Kanboard runs.";
    };

    settings = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          str
          int
          bool
        ]);

      default = { };

      description = ''
        Customize the default settings, refer to <https://github.com/kanboard/kanboard/blob/main/config.default.php>
        for details on supported values.
      '';
    };

    # Nginx
    virtualHost = mkOption {
      type = lib.types.str;
      description = ''
        FQDN for the kanboard instance.
      '';
    };

    phpfpm.settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          int
          str
          bool
        ]);
      default = {
        "pm" = "dynamic";
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "listen.owner" = "nginx";
        "catch_workers_output" = true;
        "pm.max_children" = "32";
        "pm.start_servers" = "2";
        "pm.min_spare_servers" = "2";
        "pm.max_spare_servers" = "4";
        "pm.max_requests" = "500";
      };

      description = ''
        Options for kanboard's PHPFPM pool.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = "nginx";
      home = cfg.dataDir;
      createHome = true;
    };

    services.phpfpm.pools.kanboard = {
      user = "kanboard";
      group = "nginx";

      inherit (cfg.phpfpm) settings;

      phpEnv = {
        DATA_DIR = cfg.dataDir;
      } // toStringAttrs cfg.settings;
    };

    services.nginx = {
      enable = true;
      virtualHosts."${cfg.virtualHost}" = {
        root = "${cfg.package}/share/kanboard";
        locations."/".extraConfig = ''
          rewrite ^ /index.php;
        '';

        locations."~ \\.php$".extraConfig = ''
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_pass unix:${config.services.phpfpm.pools.kanboard.socket};
          include ${config.services.nginx.package}/conf/fastcgi.conf;
          include ${config.services.nginx.package}/conf/fastcgi_params;
        '';

        locations."~ \\.(js|css|ttf|woff2?|png|jpe?g|svg)$".extraConfig = ''
          add_header Cache-Control "public, max-age=15778463";
          add_header X-Content-Type-Options nosniff;
          add_header X-XSS-Protection "1; mode=block";
          add_header X-Robots-Tag none;
          add_header X-Download-Options noopen;
          add_header X-Permitted-Cross-Domain-Policies none;
          add_header Referrer-Policy no-referrer;
          access_log off;
        '';

        extraConfig = ''
          try_files $uri /index.php;
        '';
      };
    };
  };
}
