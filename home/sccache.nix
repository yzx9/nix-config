{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux isDarwin;

  toml = pkgs.formats.toml { };

  sccacheConfig = toml.generate "sccache-config.toml" {
    cache.disk = {
      dir = "${config.home.homeDirectory}/.cache/sccache";
      size = 50 * 1024 * 1024 * 1024; # 50 GB
    };
  };
in
{
  home.packages = [
    pkgs.sccache
  ];

  xdg.configFile."sccache/config" = lib.mkIf isLinux {
    source = sccacheConfig;
  };

  home.file."Library/Application Support/Mozilla.sccache/config" = lib.mkIf isDarwin {
    source = sccacheConfig;
  };
}
