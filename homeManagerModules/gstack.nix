{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.gstack;
in
{
  options.programs.gstack = {
    enable = lib.mkEnableOption "gstack - Claude Code skills + fast headless browser";

    package = lib.mkPackageOption pkgs [ "yzx9" "gstack" ] { };

    claude-code = {
      enable = (lib.mkEnableOption "Claude Code integration (skill symlinks and settings)") // {
        default = config.programs.claude-code.enable;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # Runtime dependencies
        home.packages = [ pkgs.playwright ];
      }

      # Claude Code integration: skill symlinks and settings
      (lib.mkIf cfg.claude-code.enable {
        # Create symlinks for gstack skills
        # NOTE: dont forgot to add `auto_upgrade: false` to `~/.gstack/config.yaml` to
        # prevent gstack from upgrading itself and breaking the symlinks
        home.activation.gstack-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          GSTACK="${cfg.package}/share/gstack"

          # Main gstack directory (skills reference ~/.claude/skills/gstack/bin/ etc.)
          ln -sfn "$GSTACK" "$HOME/.claude/skills/gstack"

          # Individual skill symlinks (Claude Code discovers skills here)
          for dir in "$GSTACK"/*/; do
            skill="''${dir%/}"
            skill="''${skill##*/}"
            [ -f "$dir/SKILL.md" ] || continue
            [ "$skill" = "node_modules" ] && continue
            ln -sfn "gstack/$skill" "$HOME/.claude/skills/$skill"
          done

          # Runtime state directory
          mkdir -p "$HOME/.gstack/projects" "$HOME/.gstack/sessions"
        '';

        programs.claude-code.settings = {
          permissions.additionalDirectories = [ "~/.gstack/" ];
          sandbox.filesystem.allowWrite = [ "~/.gstack/" ];
        };
      })
    ]
  );
}
