{ config, lib, ... }:

{
  services.aerospace = {
    enable = config.purpose.gui;

    settings = {
      # You can use it to add commands that run after login to macOS user session.
      # 'start-at-login' needs to be 'true' for 'after-login-command' to work
      # Available commands: https://nikitabobko.github.io/AeroSpace/commands
      after-login-command = [ ];

      # You can use it to add commands that run after AeroSpace startup.
      # 'after-startup-command' is run after 'after-login-command'
      # Available commands : https://nikitabobko.github.io/AeroSpace/commands
      after-startup-command = [ ];

      # Start AeroSpace at login
      start-at-login = false;

      # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      # See: https://nikitabobko.github.io/AeroSpace/guide#layouts
      # The 'accordion-padding' specifies the size of accordion padding
      # You can set 0 to disable the padding feature
      accordion-padding = 30;

      # Possible values: tiles|accordion
      default-root-container-layout = "tiles";

      # Possible values: horizontal|vertical|auto
      # 'auto' means: wide monitor (anything wider than high) gets horizontal orientation,
      #               tall monitor (anything higher than wide) gets vertical orientation
      default-root-container-orientation = "auto";

      # Mouse follows focus when focused monitor changes
      # Drop it from your config, if you don't like this behavior
      # See https://nikitabobko.github.io/AeroSpace/guide#on-focus-changed-callbacks
      # See https://nikitabobko.github.io/AeroSpace/commands#move-mouse
      # Fallback value (if you omit the key): on-focused-monitor-changed = []
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      # You can effectively turn off macOS "Hide application" (cmd-h) feature by toggling this flag
      # Useful if you don't use this macOS feature, but accidentally hit cmd-h or cmd-alt-h key
      # Also see: https://nikitabobko.github.io/AeroSpace/goodies#disable-hide-app
      automatically-unhide-macos-hidden-apps = true;

      # Possible values: (qwerty|dvorak)
      # See https://nikitabobko.github.io/AeroSpace/guide#key-mapping
      key-mapping.preset = "qwerty";

      # Gaps between windows (inner-*) and between monitor edges (outer-*).
      # Possible values:
      # - Constant:     gaps.outer.top = 8
      # - Per monitor:  gaps.outer.top = [{ monitor.main = 16 }, { monitor."some-pattern" = 32 }, 24]
      #                 In this example, 24 is a default value when there is no match.
      #                 Monitor pattern is the same as for 'workspace-to-monitor-force-assignment'.
      #                 See: https://nikitabobko.github.io/AeroSpace/guide#assign-workspaces-to-monitors
      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };

      # 'main' binding mode declaration
      # See: https://nikitabobko.github.io/AeroSpace/guide#binding-modes
      #
      # 'main' binding mode must be always presented
      # Fallback value (if you omit the key): mode.main.binding = {}
      mode.main.binding =
        let
          genBindings =
            toKey: toValue:
            lib.listToAttrs (
              lib.map (c: {
                name = toKey c;
                value = toValue c;
              }) (lib.stringToCharacters "qwertasdfgzxcvb")
            );
        in
        lib.mkMerge [
          {
            # All possible keys:
            # - Letters.        a, b, c, ..., z
            # - Numbers.        0, 1, 2, ..., 9
            # - Keypad numbers. keypad0, keypad1, keypad2, ..., keypad9
            # - F-keys.         f1, f2, ..., f20
            # - Special keys.   minus, equal, period, comma, slash, backslash, quote, semicolon, backtick,
            #                   leftSquareBracket, rightSquareBracket, space, enter, esc, backspace, tab
            # - Keypad special. keypadClear, keypadDecimalMark, keypadDivide, keypadEnter, keypadEqual,
            #                   keypadMinus, keypadMultiply, keypadPlus
            # - Arrows.         left, down, up, right
            #
            # All possible modifiers: cmd, alt, ctrl, shift
            #
            # All possible commands: https://nikitabobko.github.io/AeroSpace/commands
            #
            # See: https://nikitabobko.github.io/AeroSpace/commands#exec-and-forget
            # You can uncomment the following lines to open up terminal with alt + enter shortcut (like in i3)
            # alt-enter = '''exec-and-forget osascript -e '
            # tell application "Terminal"
            #     do script
            #     activate
            # end tell'
            # '''

            # See: https://nikitabobko.github.io/AeroSpace/commands#layout
            alt-slash = "layout tiles horizontal vertical";
            alt-comma = "layout accordion horizontal vertical";

            # See: https://nikitabobko.github.io/AeroSpace/commands#focus
            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";

            # See: https://nikitabobko.github.io/AeroSpace/commands#move
            alt-shift-h = "move left";
            alt-shift-j = "move down";
            alt-shift-k = "move up";
            alt-shift-l = "move right";

            # See: https://nikitabobko.github.io/AeroSpace/commands#resize
            alt-shift-minus = "resize smart -50";
            alt-shift-equal = "resize smart +50";
            alt-shift-y = "resize smart -50";
            alt-shift-u = "resize smart +50";

            # See: https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
            alt-tab = "workspace-back-and-forth";
            # See: https://nikitabobko.github.io/AeroSpace/commands#move-workspace-to-monitor
            alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

            # See: https://nikitabobko.github.io/AeroSpace/commands#mode
            alt-shift-semicolon = "mode service";
          }

          # See: https://nikitabobko.github.io/AeroSpace/commands#workspace
          (genBindings (c: "alt-${c}") (c: "workspace ${c}"))

          # See: https://nikitabobko.github.io/AeroSpace/commands#move-node-to-workspace
          (genBindings (c: "alt-shift-${c}") (c: [
            "move-node-to-workspace ${c}"
            "workspace ${c}"
          ]))
        ];

      # 'service' binding mode declaration.
      mode.service.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];

        # reset layout
        r = [
          "flatten-workspace-tree"
          "mode main"
        ];

        # Toggle between floating and tiling layout
        f = [
          "layout floating tiling"
          "mode main"
        ];

        backspace = [
          "close-all-windows-but-current"
          "mode main"
        ];

        # sticky is not yet supported https://github.com/nikitabobko/AeroSpace/issues/2
        #s = ['layout sticky tiling', 'mode main']

        alt-shift-h = [
          "join-with left"
          "mode main"
        ];
        alt-shift-j = [
          "join-with down"
          "mode main"
        ];
        alt-shift-k = [
          "join-with up"
          "mode main"
        ];
        alt-shift-l = [
          "join-with right"
          "mode main"
        ];

        down = "volume down";
        up = "volume up";
        shift-down = [
          "volume set 0"
          "mode main"
        ];
      };

      # A: main
      # B: [B]rowser
      # C: [C]hat
      # D: [D]evelopment
      # E: [E]udic, [E]mail
      # F:
      # G: [G]raphics design: Bambu Studio, FreeCAD, Inkscape, Powerpoint
      # Q: Dbeaver
      # R:
      # S:
      # T: [T]rilium
      # V: [V]iture machine
      # W:
      # X: misc
      # Z: [Z]otero

      workspace-to-monitor-force-assignment = {
        "a" = "main";
        "b" = "main";
        "c" = "built-in";
        "d" = [
          "3"
          "built-in"
        ];
        "e" = "built-in";
        "x" = "built-in";
      };

      on-window-detected =
        let
          mkMove = workspace: appId: {
            "if".app-id = appId;
            run = "move-node-to-workspace ${workspace}";
          };
        in
        [
          (mkMove "b" "com.nixos.firefox")
          (mkMove "d" "com.kovidgoyal.kitty")
          (mkMove "e" "com.eusoft.eudic")
          (mkMove "e" "com.microsoft.Outlook")
          (mkMove "g" "com.bambulab.bambu-studio")
          (mkMove "g" "org.freecad.FreeCAD")
          (mkMove "g" "org.inkscape.Inkscape")
          (mkMove "g" "com.microsoft.Powerpoint")
          (mkMove "q" "org.jkiss.dbeaver.core.product")
          (mkMove "t" "com.electron.trilium-notes")
          (mkMove "v" "com.vmware.fusion")
          (mkMove "x" "sc.fiji")
          (mkMove "z" "org.zotero.zotero")

          {
            "if".app-id = "com.apple.finder";
            run = "layout floating";
          }

          # Most windows of wechat need to be float, including picture preview, video
          # call, etc. The only exception is the main window, howevery it's not easy to
          # detect the main window, so we just float all windows of wechat.
          {
            "if".app-id = "com.tencent.xinWeChat";
            # # Wechat set window title after creating the window, so the following line
            # # doesn't work.
            # "if".window-title-regex-substring = "WeChat"; # WeChat (Chats)
            run = [
              "layout floating"
              "move-node-to-workspace c"
            ];
          }

          {
            "if" = {
              app-id = "com.azul.zulu.java";
              app-name-regex-substring = "Launcher"; # ImageJ
            };

            run = [
              "layout floating"
              "move-node-to-workspace x"
            ];
          }
        ];
    };
  };

  system.defaults = lib.mkIf config.services.aerospace.enable {
    # Enable "Group windows by application"
    # https://nikitabobko.github.io/AeroSpace/guide#a-note-on-mission-control
    dock.expose-group-apps = true;

    # Disable "Displays have separate Spaces"
    # https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
    spaces.spans-displays = true;

    # Disable windows opening animations
    # https://nikitabobko.github.io/AeroSpace/goodies#disable-open-animations
    NSGlobalDomain.NSAutomaticWindowAnimationsEnabled = false;
  };
}
