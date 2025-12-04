{
  config,
  pkgs,
  lib,
  ...
}:

{
  age.secrets = {
    "atuin-sync-address".file = ../secrets/atuin-sync-address.age;

    # NOTE: Both the session and key file must not have a trailing newline or
    # you get Error: failed to parse header value. Several common editors (e.g.
    # Vim) will automatically add a newline on save.
    "atuin-session".file = ../secrets/atuin-session.age;
    "atuin-key".file = ../secrets/atuin-key.age;
  };

  programs.atuin =
    let
      atuin = pkgs.writeShellApplication {
        name = "atuin";
        runtimeInputs = [ pkgs.atuin ];
        text = ''
          ATUIN_SYNC_ADDRESS="$(< "${config.age.secrets."atuin-sync-address".path}")"
          export ATUIN_SYNC_ADDRESS

          ATUIN_SESSION_PATH="${config.age.secrets."atuin-session".path}"
          export ATUIN_SESSION_PATH

          ATUIN_KEY_PATH="${config.age.secrets."atuin-key".path}"
          export ATUIN_KEY_PATH

          exec atuin "$@"
        '';
      };
    in
    {
      enable = config.purpose.daily;
      package = atuin;
      flags = [ "--disable-up-arrow" ]; # or --disable-ctrl-r
      forceOverwriteSettings = true; # NOTE: DANGER: This will overwrite any user settings on each activation

      settings = {
        search_mode = "fuzzy";
        keymap_mode = "vim-insert";

        update_check = false;

        auto_sync = true;
        sync_frequency = "1h";

        # NOTE: the following settings dont work with agenix on darwin, since agenix use `getconf DARWIN_USER_TEMP_DIR` to set the paths
        #
        # session_path = config.age.secrets."atuin-session".path;
        # key_path = config.age.secrets."atuin-key".path;
      };
    };

  # Workaround to make vi-mode work with atuin
  programs.zsh.initContent = lib.optionalString config.programs.atuin.enable ''
    function zvm_after_init() {
      zvm_bindkey viins '^R' atuin-search
      zvm_bindkey vicmd '^R' atuin-search
    }
  '';
}
