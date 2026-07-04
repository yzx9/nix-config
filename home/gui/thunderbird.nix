{ config, ... }:

{
  programs.thunderbird = {
    enable = with config.purpose; gui && daily;
  };
}
