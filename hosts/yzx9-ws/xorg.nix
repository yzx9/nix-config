{ ... }:

{
  # https://nixos.wiki/wiki/Using_X_without_a_Display_Manager
  services.xserver = {
    enable = true;
    autorun = false;
    displayManager.startx.enable = true;
  };
}
