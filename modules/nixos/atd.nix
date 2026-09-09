{ config, ... }:

{
  services.atd.enable = config.my.host.daily;
}
