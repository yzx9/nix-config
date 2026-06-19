# Github cli tool
{ config, ... }:

{
  programs.gh = {
    enable = config.purpose.daily;

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
