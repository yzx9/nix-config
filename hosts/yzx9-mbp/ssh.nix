{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;
in
{
  # ssh
  age.secrets = {
    id-auth = {
      file = ../../secrets/id-auth_root.age;
      path = "${ssh}id_auth";
      mode = "400";
    };

    id-git = {
      file = ../../secrets/id-git_root.age;
      path = "${ssh}id_git";
      mode = "400";
    };

    id-github = {
      file = ../../secrets/id-github_root.age;
      path = "${ssh}id_github";
      mode = "400";
    };

    id-lab = {
      file = ../../secrets/id-lab.age;
      path = "${ssh}id_lab";
      mode = "400";
    };
  };

  home.file.".ssh/id_auth.pub".source = ../../secrets/id-auth.pub;
  home.file.".ssh/id_github.pub".source = ../../secrets/id-github.pub;

  programs.ssh = {
    matchBlocks."github.com".identityFile = (toSshPath config.age.secrets.id-github.path);
  };
}
