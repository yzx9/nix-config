{ config, lib, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
  toSshPath = path: lib.removePrefix ssh path;
in
{
  age.secrets = {
    id-github = {
      file = ../../secrets/id-github_yzx9-mbp.age;
      path = "${ssh}id_github";
      mode = "400";
    };

    ssh-config_yzx9-mbp = {
      file = ../../secrets/ssh-config_yzx9-mbp.age;
      path = "${ssh}config-agenix";
    };
  };

  programs.ssh = {
    includes = [
      (toSshPath config.age.secrets.ssh-config_yzx9-mbp.path)
    ];

    matchBlocks."github.com".identityFile = (toSshPath config.age.secrets.id-github.path);
  };
}
