{ nixpkgs, git-hooks, ... }:

system:

let
  pkgs = nixpkgs.legacyPackages.${system};

  # git pre-commit hook, auto-installed into the dev shell. direnv loads
  # `default` (via `use flake` in .envrc), whose shellHook runs
  # pre-commit-checks.shellHook to set core.hooksPath — so `git commit`
  # formats the staged files. Unlike the old smart-format.sh PostToolUse
  # hook, this fires for *every* write path (shell / heredoc / git),
  # closing the formatter-bypass gap.
  #
  # nixfmt only: this repo is ~150 .nix files, so nixfmt does the real
  # work. The few non-Nix files (CI YAML, READMEs) are hand-maintained and
  # don't warrant pulling in prettier.
  pre-commit-checks = git-hooks.lib.${system}.run {
    src = ./.;
    hooks = {
      nixfmt.enable = true;
    };
  };
in
{
  default = pkgs.mkShell {
    packages = with pkgs; [
      just
      jq

      # formatter (also driven by the pre-commit hook above)
      nixfmt
    ];

    shellHook = pre-commit-checks.shellHook;
  };
}
