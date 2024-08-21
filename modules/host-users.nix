#############################################################
#
#  Host & Users configuration
#
#############################################################

{
  vars,
  pkgs,
  lib,
  ...
}:

let
  username = vars.user.name;
in
{
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} =
    {
      description = username;
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      home = "/home/${username}";
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      # packages = with pkgs; [];
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin { home = "/Users/${username}"; };

  nix.settings.trusted-users = [ username ];
}
