{ config, lib, ... }:

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

    userName = git.name;
    userEmail = git.email;

    # includes = [
    #   {
    #     # use different email & name for work
    #     path = "~/work/.gitconfig";
    #     condition = "gitdir:~/work/";
    #   }
    # ];

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      submodule.fetchJobs = 4;
    };

    signing = {
      signByDefault = true;
      key = "~/.ssh/id_git.pub";
      format = "ssh";
    };

    delta = {
      enable = config.purpose.daily;
      options = {
        features = "side-by-side";
      };
    };

    aliases = {
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
}
