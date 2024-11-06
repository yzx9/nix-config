{ ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ./frp.nix
    ./rss.nix
    ./xorg.nix
  ];
}
