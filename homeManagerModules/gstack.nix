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

    claude-code.enable =
      (lib.mkEnableOption "Claude Code integration (skill symlinks and settings)")
      // {
        default = config.programs.claude-code.enable;
      };

    hermes-agent.enable = (lib.mkEnableOption "Hermes Agent integration (skill symlinks)") // {
      default = config.programs.hermes-agent.enable;
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

      # Hermes Agent integration: skill symlinks
      (lib.mkIf cfg.hermes-agent.enable (
        let
          hermesCfg = config.programs.hermes-agent;
          hermesHome = "${hermesCfg.stateDir}/.hermes";
        in
        {
          home.activation.gstack-hermes-skills =
            lib.hm.dag.entryAfter
              [
                "writeBoundary"
                "hermesAgentSetup"
              ]
              ''
                GSTACK="${cfg.package}/share/gstack"

                # Compatibility symlink: generated hermes content references ~/.hermes
                # but the nix module uses ${hermesHome} as HERMES_HOME.
                ln -sfn "${hermesHome}" "$HOME/.hermes"

                # Main gstack directory (runtime assets: bin/, browse/, etc.)
                mkdir -p "${hermesHome}/skills"
                ln -sfn "$GSTACK" "${hermesHome}/skills/gstack"

                # Individual hermes skill symlinks (from .hermes/skills/ in the package)
                if [ -d "$GSTACK/.hermes/skills" ]; then
                  for dir in "$GSTACK/.hermes/skills"/*/; do
                    skill="''${dir%/}"
                    skill="''${skill##*/}"
                    [ "$skill" = "gstack" ] && continue
                    [ -f "$dir/SKILL.md" ] || continue
                    ln -sfn "$GSTACK/.hermes/skills/$skill" "${hermesHome}/skills/$skill"
                  done
                fi

                # Runtime state directory
                mkdir -p "$HOME/.gstack/projects" "$HOME/.gstack/sessions"
              '';
        }
      ))
    ]
  );
}
