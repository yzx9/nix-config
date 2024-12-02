{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;
in
{
  # ssh
  age.secrets = {
    id-git = {
      file = ../../secrets/id-git_yzx9-mbp.age;
      path = "${ssh}id_git";
      mode = "400";
    };

    id-github = {
      file = ../../secrets/id-github_yzx9-mbp.age;
      path = "${ssh}id_github";
      mode = "400";
    };
  };

  home.file.".ssh/id_github.pub".source = ../../secrets/id-github.pub;

  programs.ssh = {
    matchBlocks."github.com".identityFile = (toSshPath config.age.secrets.id-github.path);
  };
}
