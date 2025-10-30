{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config.vars.user) git;
in
{
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ~/.gitconfig
  '';

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
    settings = {
      git_protocol = "ssh";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };

  # Gitmoji: An emoji guide for your commit messages
  # homepage: https://gitmoji.dev/
  home.packages = lib.optionals config.purpose.dev.enable [ pkgs.gitmoji-cli ];

  home.file.".gitmojirc.json" = lib.mkIf config.purpose.dev.enable {
    text = lib.strings.toJSON {
      "autoAdd" = false;
      "emojiFormat" = "emoji";
      "scopePrompt" = true;
      "messagePrompt" = true;
      "capitalizeTitle" = true;
      "gitmojisUrl" = "https://gitmoji.dev/api/gitmojis";
    };
  };
}
