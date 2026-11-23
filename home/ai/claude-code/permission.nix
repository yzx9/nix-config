{
  pkgs,
  lib,
  ...
}:

{
  # See: https://code.claude.com/docs/en/settings
  programs.claude-code.settings = {
    permissions =
      let
        mkBashCmds = lib.map (cmd: "Bash(${cmd} *)");
        mkBashSubCmds = cmd: lib.map (subcmd: "Bash(${cmd} ${subcmd} *)");
        mkHmMcps = lib.map (mcp: "mcp__plugin_hm_${mcp}");
        mkHmMcpCmds = mcp: lib.map (cmd: "mcp__plugin_hm_${mcp}__${cmd}");
      in
      {
        # Default permission mode
        defaultMode = "auto";

        # Deny > Ask > Allow
        deny = mkHmMcpCmds "tavily" [ "tavily_research" ]; # Too expensive

        ask =
          (mkBashSubCmds "git" [
            "push"
          ])
          ++ (mkBashSubCmds "gh pr" [
            "close"
            "create"
          ])
          ++ (mkBashSubCmds "gh issue" [
            "close"
            "delete"
          ]);

        allow = [
          "Read(**/*)" # allow reading all files, but deny specific sensitive files below
          "Read(~/.cargo/registry/*)"
          "Read(/nix/store/*)"
          "Agent(isolation:worktree)"

          "EnterWorktree"
          "Search"
          "WebFetch" # allow any fetches
          "WebSearch" # allow any searches
        ]
        ++ (mkBashCmds [
          "curl"
          "rg"
          "mvn"
          "nix-instantiate"
          "nix-prefetch-url"
        ])
        ++ (mkBashSubCmds "git" [
          "add"
          "commit"
          "diff"
          "fetch"
          "log"
          "pull"
          "rebase"
          "stash"
          "status"
        ])
        ++ (mkBashSubCmds "gh" [
          "run"
          "workflow"
        ])
        ++ (mkBashSubCmds "cargo" [
          "build"
          "check"
          "clippy"
          "fmt"
          "test"
        ])
        ++ (mkBashSubCmds "nix" [
          "build"
          "eval"
          "hash"
          "log"
          "why-depends"
        ])
        ++ (mkHmMcps [
          "tavily"
        ]);

        # Additional working directories Claude can access
        # additionalDirectories = [ ];
      };

    sandbox = {
      enabled = true;
      autoAllowBashIfSandboxed = true;
      failIfUnavailable = true;

      excludedCommands = [
        "codex *"
        "docker *"
        "gh *"
        "mvn *"
        "nix *"
        "cargo build *"
        "cargo check *"
        "cargo clippy *"
        "cargo test *"
      ];

      # Default read behavior: read access to the entire computer
      filesystem.allowWrite = [
        "~/.cache/"
        "~/.cargo" # rust dependencies and cache
        "~/.codex" # codex state and cache
        "~/.gradle" # gradle dependencies and cache
        "~/.m2/" # maven dependencies
        "~/.matplotlib/" # python plotting
        "~/.npm/" # npm packages and cache
        "~/.local/share/direnv" # direnv config
        "~/.local/state/pnpm" # pnpm state
        "~/go/pkg" # go dependencies and cache
      ]
      ++ lib.optionals pkgs.stdenvNoCC.hostPlatform.isLinux [
        "~/.local/share/pnpm" # pnpm store
      ]
      ++ lib.optionals pkgs.stdenvNoCC.hostPlatform.isDarwin [
        "~/Library/Caches"
        "~/Library/pnpm" # pnpm v11 global store location, otherwise pnpm falls back to <project>/.pnpm-store
      ];

      network = {
        allowedDomains = [
          "registry.yarnpkg.com"
          "raw.githubusercontent.com"
          "files.pythonhosted.org"
          "*.crates.io"
          "*.github.com"
          "*.npmjs.org"
          "*.pypi.org"

          # codex
          "api.openai.com"
          "chatgpt.com"
        ];
        allowAllUnixSockets = true;
        allowLocalBinding = true;
      };
    };
  };
}
