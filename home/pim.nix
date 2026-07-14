# Personal Information Management
{
  config,
  pkgs,
  lib,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };
in
lib.mkIf config.my.host.daily {
  home.packages = [ pkgs.aim ];

  xdg.configFile."aim/config.toml".source = tomlFormat.generate "config.toml" {
    core = {
      calendar_path = "${config.home.homeDirectory}/.local/share/calendars/home/";
      default_due = "24h";
      default_priority = "low";
    };
  };
}
