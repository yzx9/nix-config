# Worktrunk (git worktree management)
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Propagate direnv-allow from the primary worktree to a newly-created one.
  # Run as a worktrunk `post-start` user hook (background, no approval needed).
  # Args: <worktree-path> <primary-worktree-path>
  propagateDirenv = pkgs.writeShellScript "wt-direnv-propagate" ''
    worktree="''${1:?}"; primary="''${2:?}"
    # No .envrc in the primary → direnv isn't relevant here; stay silent.
    [ -f "$primary/.envrc" ] || exit 0
    command -v direnv >/dev/null 2>&1 || exit 0
    if (cd "$primary" && direnv status --json | ${lib.getExe pkgs.jq} -e --arg p "$(pwd -P)/.envrc" \
        '.state.foundRC.path == $p and .state.foundRC.allowed == 0') >/dev/null 2>&1; then
      echo "wt: primary direnv is allowed — propagating to $worktree" >&2
      direnv allow "$worktree"
    else
      echo "wt: primary direnv present but not allowed — skipping" >&2
    fi
  '';
in
{
  programs.worktrunk = {
    enable = config.purpose.dev.enable;

    claudeCodeIntegration.skills = false;

    settings = {
      aliases = {
        rm = "wt remove {{ args }}";
        ls = "wt list {{ args }}";
      };

      merge.squash = false;

      # LLM-generated commit messages (https://worktrunk.dev/llm-commits/).
      commit.generation.command = "MAX_THINKING_TOKENS=0 claude -p --no-session-persistence --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt=''";

      # On worktree creation: if the primary repo's direnv is allowed, allow the new worktree.
      "pre-start".direnv = "${propagateDirenv} {{ worktree_path }} {{ primary_worktree_path }}";
    };
  };
}
