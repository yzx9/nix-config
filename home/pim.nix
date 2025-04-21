# Personal Information Management
{
  config,
  pkgs,
  lib,
  ...
}:

let
  enable = config.purpose.daily;

  toPythonBool = value: if value == true then "True" else "False";
  toSimplePythonVar =
    key: value:
    if lib.isBool value then
      "${key} = ${toPythonBool value}"
    else if lib.isInt value then
      "${key} = ${builtins.toString value}"
    else if lib.isString value then
      "${key} = '${value}'"
    else
      throw "Unsupported type for ${key}: ${lib.typeOf value}";

  toSimplePythonVars = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList toSimplePythonVar attrs);
in
{
  # calendar
  programs.khal = {
    inherit enable;
  };

  accounts.calendar = {
    basePath = "${config.xdg.dataHome}/calendars";

    accounts.personal.khal = {
      inherit enable;
    };
  };

  # Todo Management
  home.packages = lib.optionals enable (with pkgs; [ todoman ]);

  xdg.configFile."todoman/config.py".text = toSimplePythonVars {
    path = "${config.xdg.dataHome}/calendars/*";
    date_format = "%Y-%m-%d";
    time_format = "%H:%M";
    default_list = "personal";
    default_due = 48;
    startable = true;
    humanize = true;
  };
}
