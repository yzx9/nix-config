##########################################################################
#
#  Install all apps and packages here.
#
##########################################################################

# Darwin
#
# NOTE: Your can find all available options in:
#    https://daiderd.com/nix-darwin/manual/index.html
#
# NOTE: To remove the uninstalled APPs icon from Launchpad:
#    1. `sudo nix store gc --debug && sudo nix-collect-garbage --delete-old`
#    2. click on the uninstalled APP's icon in Launchpad, it will show a question mark
#    3. if the app starts normally:
#        1. right click on the running app's icon in Dock, select "Options" -> "Show in Finder" and delete it
#    4. hold down the Option key, a `x` button will appear on the icon, click it to remove the icon

{ pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    git # Required by nix
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

    # system
    util-linux
    dosfstools # fat filesystem
    e2fsprogs # ext filesystem
  ];

  programs.zsh.enable = true;

  environment.variables.EDITOR = "vim";
}
