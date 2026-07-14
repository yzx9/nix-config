{ config, ... }:

{
  programs.thunderbird = {
    enable = with config.my.host; gui && daily;
  };
}
