# Personal Information Management
{
  config,
  pkgs,
  lib,
  ...
}:

let
  enable = config.purpose.daily;
  basePath = "${config.xdg.dataHome}/calendars";

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
  ####################
  #     Calendar     #
  ####################

  programs.khal = {
    inherit enable;

    # https://khal.readthedocs.io/en/latest/configure.html#locale-timeformat
    settings.default = {
      default_calendar = "personal";
    };
  };

  accounts.calendar = {
    inherit basePath;

    accounts.personal.khal = {
      inherit enable;
    };
  };

  #####################
  #  Todo Management  #
  #####################

  home.packages = lib.optionals enable (with pkgs; [ todoman ]);

  # docs: https://todoman.readthedocs.io/en/stable/configure.html
  xdg.configFile."todoman/config.py".text = toSimplePythonVars {
    path = "${basePath}/*";
    date_format = "%Y-%m-%d";
    time_format = "%H:%M";
    default_list = "personal";
    default_priority = 8; # high: 1, medium: 5, low: 9, and 0 means no priority at all.
    default_due = 72;
  };
}
