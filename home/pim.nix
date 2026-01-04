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

  tomlFormat = pkgs.formats.toml { };
in
lib.mkIf enable (
  lib.mkMerge [
    {
      home.packages = [ pkgs.aim ];

      xdg.configFile."aim/config.toml".source = tomlFormat.generate "config.toml" {
        core = {
          calendar_path = "~/.local/share/calendars/home/";
          default_due = "24h";
          default_priority = "low";
        };
      };
    }

    ####################
    #     Calendar     #
    ####################
    {
      programs.khal = {
        enable = true;

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
    }

    #####################
    #  Todo Management  #
    #####################
    {
      home.packages = [ pkgs.todoman ];

      # docs: https://todoman.readthedocs.io/en/stable/configure.html
      xdg.configFile."todoman/config.py".text =
        let
          toPythonBool = value: if value == true then "True" else "False";
          toPythonVar =
            key: value:
            if lib.isBool value then
              "${key} = ${toPythonBool value}"
            else if lib.isInt value then
              "${key} = ${toString value}"
            else if lib.isString value then
              "${key} = '${value}'"
            else
              throw "Unsupported type for ${key}: ${lib.typeOf value}";

          toPythonVars = attrs: (lib.concatStringsSep "\n" (lib.mapAttrsToList toPythonVar attrs)) + "\n";
        in
        toPythonVars {
          path = "${basePath}/*";
          date_format = "%Y-%m-%d";
          time_format = "%H:%M";
          columns = "auto";
          default_list = "home";
          default_priority = 9; # high: 1, medium: 5, low: 9, and 0 means no priority at all.
          default_due = 24;
          default_command = "list --startable --sort=priority,due --due 48";
        };
    }
  ]
)
