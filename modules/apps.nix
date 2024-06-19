{ pkgs, ... }:
{

  ##########################################################################
  # 
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  # 
  #  Fell free to modify this file to fit your needs.
  #
  ##########################################################################

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
      "openvpn-connect"
      "steam"
      "raspberry-pi-imager"

      # dev
      "docker" # nixpkgs docker is breaked, see: https://github.com/LnL7/nix-darwin/issues/112
      "visual-studio-code"
      "xmake"

      # science
      "zotero"
      "master-pdf-editor"
      "eudic"
      "fiji"

      # design
      "blender"
      "preform"
      "ideamaker"
      "inkscape"
      "krita"

      # ldap
      "apache-directory-studio"
      "oracle-jdk" # required by apache-directory-studio
    ];
  };
}
