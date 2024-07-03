##########################################################################
#
#  Install all apps and packages here.
#
#  NOTE: Your can find all available options in:
#    https://daiderd.com/nix-darwin/manual/index.html
#
#  NOTE：To remove the uninstalled APPs icon from Launchpad:
#    1. `sudo nix store gc --debug` & `sudo nix-collect-garbage --delete-old`
#    2. click on the uninstalled APP's icon in Launchpad, it will show a question mark
#    3. if the app starts normally:
#        1. right click on the running app's icon in Dock, select "Options" -> "Show in Finder" and delete it
#    4. hold down the Option key, a `x` button will appear on the icon, click it to remove the icon
#
##########################################################################

{ pkgs, ... }:

{
  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    git # required by nix
  ];

  # To make this work, homebrew need to be installed manually, see https://brew.sh
  # 
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "zap"; # 'zap': uninstalls all formulae(and related files) not listed here.
    };

    taps = [ ];

    # `brew install`
    brews = [ ];

    # `brew install --cask`
    casks = [
      # system
      "middleclick"
      "snipaste"
      "maccy"
      "logitech-options"
      "sfm"
      "firefox"
      "microsoft-edge"
      "vmware-fusion"
      "steam"
      "raspberry-pi-imager"
      "canon-ufrii-driver"

      # dev
      "docker" # nixpkgs docker is breaked, see: https://github.com/LnL7/nix-darwin/issues/112
      "visual-studio-code"

      # science
      "zotero"
      # "master-pdf-editor"
      "eudic"
      "fiji"

      # design
      "blender"
      "krita"
      # "preform"
      # "ideamaker"
      # "inkscape"

      # ldap
      "apache-directory-studio"
      "oracle-jdk" # required by apache-directory-studio
    ];
  };
}
