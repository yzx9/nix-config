{ config, lib, ... }:

let
  inherit (config.my.user) git;

  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = lib.removePrefix ssh;
in
lib.mkMerge [
  {
    home.file.".ssh/id_git.pub".source = ../secrets/id-git.pub;

    programs.git = {
      enable = true;
      lfs.enable = config.my.host.daily;

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

  (lib.mkIf config.my.host.trusted {
    age.secrets = {
      id-git = {
        file = ../secrets/id-git.age;
        path = "${ssh}id_git";
        mode = "400";
      };

      id-github = {
        file = ../secrets/id-github.age;
        path = "${ssh}id_github";
        mode = "400";
      };
    };

    home.file.".ssh/id_github.pub".source = ../secrets/id-github.pub;

    programs.ssh.settings."github.com".identityFile = toSshPath config.age.secrets.id-github.path;
  })
]
