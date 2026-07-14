# Github cli tool
{ config, ... }:

{
  programs.gh = {
    enable = config.my.host.daily;

    gitCredentialHelper.enable = true;

    settings = {
      git_protocol = "ssh";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
}
