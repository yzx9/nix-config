{ config, ... }:

let
  inherit (config.vars.user) git;
in
{
  home.file.".ssh/id_git.pub".source = ../secrets/id-git.pub;

  programs.git = {
    enable = true;
    lfs.enable = config.purpose.daily;

    # includes = [
    #   {
    #     # use different email & name for work
    #     path = "~/work/.gitconfig";
    #     condition = "gitdir:~/work/";
    #   }
    # ];

    signing = {
      signByDefault = true;
      key = "~/.ssh/id_git.pub";
      format = "ssh";
    };

    settings = {
      user = {
        name = git.name;
        email = git.email;
      };

      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      submodule.fetchJobs = 4;

      alias = {
        # common aliases
        br = "branch";
        co = "checkout";
        st = "status";
        ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
        ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
        cm = "commit -m";
        ca = "commit -am";
        dc = "diff --cached";
        amend = "commit --amend -m";

        # aliases for submodule
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";
      };
    };
  };

  # Github cli tool
  programs.gh = {
    enable = config.purpose.daily;

    gitCredentialHelper.enable = true;

    settings = {
      git_protocol = "ssh";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };

  # Worktrunk (git worktree management)
  programs.worktrunk = {
    enable = config.purpose.dev.enable;

    claudeCodeIntegration = {
      statusLine = true;
      worktreeHooks = true;
    };

    settings = {
      # LLM-generated commit messages (https://worktrunk.dev/llm-commits/).
      commit.generation.command = "MAX_THINKING_TOKENS=0 claude -p --no-session-persistence --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt=''";
    };
  };
}
