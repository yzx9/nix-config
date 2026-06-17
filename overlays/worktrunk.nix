{ ... }:
final: prev: {
  # Install worktrunk's Claude Code skill markdown (`/worktrunk`, `/wt-switch-create`)
  # alongside the binary. Reuses the package's own `src` (fetchFromGitHub), so the
  # skills stay version-aligned with `wt`. The nixpkgs package only ships completions.
  worktrunk = prev.worktrunk.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      # -L dereferences symlinks (e.g. skills/worktrunk/reference/README.md → repo
      # root), so no dangling symlinks end up in $out.
      cp -RL ${old.src}/skills $out/
    '';
  });
}
