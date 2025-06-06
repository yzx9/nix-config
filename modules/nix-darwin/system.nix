###################################################################################
#
#  macOS's System configuration
#
#  All the configuration options are documented here:
#    https://nix-darwin.github.io/nix-darwin/manual/index.html#sec-options
#
###################################################################################

{ config, pkgs, ... }:

let
  inherit (config) vars;
  username = vars.user.name;
in
{
  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 6;

    # activationScripts are executed every time you boot the system or run `darwin-rebuild`.
    activationScripts.postActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      menuExtraClock.Show24Hour = true; # show 24 hour clock
    };

    primaryUser = username;
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  networking.hostName = vars.hostname;
  networking.computerName = vars.hostname;
  system.defaults.smb.NetBIOSName = vars.hostname;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  environment.shells = [ pkgs.zsh ];
  environment.pathsToLink = [ "/share/zsh" ];

  # disable save gpg in keychain, which cause double password prompt, see also:
  # https://gpgtools.tenderapp.com/kb/gpg-mail-faq/gpg-mail-hidden-settings#disable-option-to-store-password-in-macos-keychain
  system.defaults.CustomUserPreferences = {
    "org.gpgtools.common".DisableKeychain = true;
  };

  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/programs/gnupg.nix
  # try `pkill gpg-agent` if you have issues(such as `no pinentry`)
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  users.users = {
    ${username} = {
      home = "/Users/${username}";
    };
  };
}
