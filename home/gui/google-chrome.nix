{ config, ... }:

{
  programs.google-chrome.enable = with config.my.host; gui && daily;
}
