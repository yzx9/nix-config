{ username, pkgs, ... }:

let
  homepath = "/Users/${username}";
in {
  home.packages = with pkgs; [
    gopass

    # you have to run `gopass-jsonapi configure` mannually, because I dont know how to do it automatically
    gopass-jsonapi
  ];

  # home.file = {
  #   "Library/Application Support/Mozilla/NativeMessagingHosts/com.justwatch.gopass.json".text = ''
  #     {
  #       "name": "com.justwatch.gopass",
  #       "description": "Gopass wrapper to search and return passwords",
  #       "path": "${homepath}/.config/gopass/gopass_wrapper.sh",
  #       "type": "stdio",
  #       "allowed_extensions": [
  #         "{eec37db0-22ad-4bf1-9068-5ae08df8c7e9}"
  #       ]
  #     }
  #   '';

  #   ".config/gopass/gopass_wrapper.sh".text = ''
  #     #!/bin/sh

  #     export PATH="$PATH:$HOME/.nix-profile/bin" # required for Nix
  #     export PATH="$PATH:/usr/local/bin" # required on MacOS/brew
  #     export PATH="$PATH:/usr/local/MacGPG2/bin" # required on MacOS/GPGTools GPGSuite
  #     export GPG_TTY="$(tty)"

  #     # Uncomment to debug gopass-jsonapi
  #     # export GOPASS_DEBUG_LOG=/tmp/gopass-jsonapi.log

  #     if [ -f ~/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
  #       source ~/.gpg-agent-info
  #       export GPG_AGENT_INFO
  #     else
  #       eval $(gpg-agent --daemon)
  #     fi

  #     export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

  #     ${homepath}/.nix-profile/bin/gopass-jsonapi listen

  #     exit $?
  #   '';
  # };
}
