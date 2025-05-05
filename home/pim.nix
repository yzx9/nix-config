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
    locale = {
      # timeformat: https://docs.python.org/3/library/time.html#time.strftime
      longdatetimeformat = "%c"; # Sat Dec 21 21:45:00 2013
      datetimeformat = "%c"; # Sat Dec 21 21:45:00 2013
      longdateformat = "%Y-%m-%d";
      dateformat = "%Y-%m-%d";
      timeformat = "%H:%M";

      default_timezone = "Asia/Shanghai";
      local_timezone = "Asia/Shanghai";
      firstweekday = 0; # Monday is 0 and Sunday is 6
    };

    settings = {
      default = {
        default_calendar = "work";
        highlight_event_days = true;
        print_new = "event";
      };

      highlight_days = {
        color = "light cyan";
        default_color = "yellow";
      };
    };
  };

  accounts.calendar = {
    inherit basePath;

    accounts = {
      home.khal = {
        inherit enable;
        color = "dark green";
      };

      work.khal = {
        inherit enable;
        color = "dark blue";
      };
    };
  };

  #####################
  #  Todo Management  #
  #####################

  home.packages = lib.optionals enable [
    (pkgs.todoman.overrideAttrs {
      # https://github.com/pimutils/todoman/pull/576
      src = pkgs.fetchFromGitHub {
        owner = "yzx9";
        repo = "todoman";
        rev = "f9f63ca95bb8fce31a353e494f85cec7cf5ca4c9";
        hash = "sha256-SxKBym8oj2ri6tBVyVB++Nf8emDW1//TsbNAfWHpi44=";
      };

      disabledTests = [
        "test_filtering_lists"
        "test_main"
        "test_missing_path"
      ];
    })
  ];

  # docs: https://todoman.readthedocs.io/en/stable/configure.html
  xdg.configFile."todoman/config.py".text = toSimplePythonVars {
    path = "${basePath}/*";
    date_format = "%Y-%m-%d";
    time_format = "%H:%M";
    columns = "auto";
    default_list = "home";
    default_priority = 8; # high: 1, medium: 5, low: 9, and 0 means no priority at all.
    default_due = 24;
    default_command = "list --startable --sort=priority,due --due 48";
  };
}
