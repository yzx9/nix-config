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
}
