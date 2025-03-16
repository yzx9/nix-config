{ pkgs, lib, ... }:

{
  # networking
  networking = {
    networkmanager.enable = lib.mkForce false;

    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # Enables wireless support via wpa_supplicant.
    wireless = {
      enable = true;
      networks = {
        chn.pskRaw = "935490cd011d5c6af8fa1b12a2fce67437d6fcc800daf278b0e6342ca3e97374";
      };
    };
  };

  # GNOME: https://wiki.nixos.org/wiki/GNOME
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Excluding GNOME applications
  environment.gnome.excludePackages = with pkgs; [
    orca # screen reader
    evince # document viewer
    # file-roller
    geary # email client
    gnome-disk-utility
    # seahorse # managing encryption keys and passwords in the GNOME Keyring
    # sushi # quick previewer for Files
    # sysprof # modern system-wide profiling tool
    #
    # gnome-shell-extensions
    #
    # adwaita-icon-theme
    # nixos-background-info
    gnome-backgrounds
    # gnome-bluetooth
    # gnome-color-manager
    # gnome-control-center
    # gnome-shell-extensions
    gnome-tour # GNOME Shell detects the .desktop file on first log-in.
    gnome-user-docs
    # glib # for gsettings program
    # gnome-menus
    # gtk3.out # for gtk-launch program
    # xdg-user-dirs # Update user dirs as described in https://freedesktop.org/wiki/Software/xdg-user-dirs/
    # xdg-user-dirs-gtk # Used to create the default bookmarks
    #
    baobab # disk usage analyzer
    epiphany # web browser
    gnome-text-editor
    gnome-calculator
    gnome-calendar
    gnome-characters
    # gnome-clocks
    gnome-console
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    # gnome-system-monitor
    gnome-weather
    # loupe
    # nautilus
    gnome-connections
    simple-scan
    snapshot
    totem # video
    yelp # help viewer
    gnome-software # software store
  ];

  # Managing GNOME extensions
  environment.systemPackages = with pkgs.gnomeExtensions; [
    keep-awake
  ];
}
