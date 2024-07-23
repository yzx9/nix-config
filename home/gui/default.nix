{ lib, ... }:

{
  imports = [
    ./apps.nix
    ./kitty.nix
  ];

  options.gui = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install GUI apps.";
    };
  };
}
