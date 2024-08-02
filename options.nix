{ lib, ... }:

{
  options.gui = {
    enable = lib.mkEnableOption "GUI apps";
  };
}
