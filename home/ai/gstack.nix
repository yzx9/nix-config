{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.programs.claude-code.enable {
  # Create symlinks for gstack skills
  # NOTE: dont forgot to add `auto_upgrade: false` to `~/.gstack/config.yaml` to
  # prevent gstack from upgrading itself and breaking the symlinks
  home.activation.gstack-skills = lib.mkIf config.programs.claude-code.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      GSTACK="${pkgs.yzx9.gstack}/share/gstack"

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
    ''
  );

  home.packages = with pkgs; [ playwright ];

  programs.claude-code.settings = {
    # Additional working directories Claude can access
    permissions.additionalDirectories = [ "~/.gstack/" ]; # gstack runtime state (sessions, projects, etc.)
    sandbox.filesystem.allowWrite = [ "~/.gstack/" ];
  };
}
