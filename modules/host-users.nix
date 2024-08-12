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
  networking.hostName = vars.hostname;
  networking.computerName = vars.hostname;
  system.defaults.smb.NetBIOSName = vars.hostname;

  users.users.${username} = {
    home = (
      lib.optionalString pkgs.stdenv.isLinux "/home/${username}"
      + lib.optionalString pkgs.stdenv.isDarwin "/Users/${username}"
    );
    description = username;
  };

  nix.settings.trusted-users = [ username ];
}
